# Bytebase Release：多版本文件与同库互斥演示

本仓库已在 2026-10-15 实际跑通。GitHub Actions 创建 Release、Plan 和 Rollout，然后在 Bytebase 页面手动运行。每个计划只有一个目标数据库、一个迁移任务；一个任务可以包含多份版本文件。

## 实际结果

| 计划 | Release | 实际执行 | 结果 |
| --- | --- | --- | --- |
| [104](https://cloud.bytebase.com/projects/gha-wdhk/plans/104) | `demo_A_20261015-RC00` | 版本 1、2、3 | 成功，30.2 秒 |
| [105](https://cloud.bytebase.com/projects/gha-wdhk/plans/105) | `demo_B_20261015-RC00` | 跳过 1～3，执行 4 | 成功，201 毫秒 |
| [106](https://cloud.bytebase.com/projects/gha-wdhk/plans/106) | `demo_C_20261015-RC00` | 跳过 1～4，执行 5，等待 90 秒 | 成功，约 90 秒 |
| [107](https://cloud.bytebase.com/projects/gha-wdhk/plans/107) | `demo_C_20261015-RC01` | 在 106 运行时等待；随后跳过全部 5 个版本 | 自动完成，执行耗时 181 毫秒，不含排队时间 |

表中的 1～5 对应完整版本号 `20261014000001`～`20261014000005`。A/B 验证包内顺序与已应用版本跳过；实际捕获同库排队的是 C106/C107。

## 在页面上操作

1. 进入 [Actions 工作流](https://github.com/w1030777212/migration_test_1/actions/workflows/release.yml)，点击 **Run workflow**，分支选择 `main`。
2. `release_set` 选择 A（前三个文件）、B（前四个文件）或 C（全部 SQL 文件）。流水线成功后的 Summary 提供 Bytebase 计划链接。
3. 打开计划，查看 Release 的文件列表和部署任务。选中目标数据库任务，点击 **运行**，在弹窗中确认运行。
4. 观察任务状态、执行记录和各版本 SQL 日志。这里由页面触发执行，工作流没有自动部署步骤。

本次 GitOps 流程直接创建 Plan / Rollout，未创建单独的 Issue 审批工单。一个 Release 内的多个版本文件在同一个任务中执行，并非每个文件各建一个任务。

## 再次复现同库排队

**版本 1～5 已在当前数据库应用。直接重跑现有 A/B/C 会跳过这些版本，无法再次看到 90 秒等待。**

1. 在 `migrations/` 新增尚未使用的版本，例如 `20261014000006_wait_mutex_dml.sql`，内容如下，然后提交到 `main`：

   ```sql
   -- A new version is required for another mutex observation.
   SELECT pg_sleep(90);
   ```

2. 选择 C，手动运行工作流两次，得到两个新计划。先准备好两个计划的页面，再启动其中一个。
3. 第一个显示 **正在执行** 后，在其 90 秒等待期间立刻运行第二个。第二个应保持 **待执行 / 等待执行**。
4. 第一个完成后，第二个会自动继续。因为新版本此时也已应用，第二个通常只做同步并很快完成。

不要通过修改已应用版本的 SQL 来重复演示；以后每次需要一个新的、未使用的版本号。跨 Release 的互斥不代表调度器按所有 Release 的版本号排序。

## 当前配置

- Bytebase 项目：`gha-wdhk`（新项目）。
- 目标库：`bb_sample_c2c0430cc93711a1`，页面环境标签为 **Prod**，实例为 **Sample Project Instance**。
- 工作负载身份：`release-demo-20261015@gha-wdhk.workload.bytebase.com`，项目角色为 **GitOps 服务代理**。
- 仅信任本仓库 `main` 分支；issuer 为 `https://token.actions.githubusercontent.com`，audience 为 `bytebase`。
- 实际 subject：`repo:w1030777212@92676742/migration_test_1@1420218892:ref:refs/heads/main`。
- Cloud 镜像：`bytebase/bytebase-action:cloud`；本次 CLI 和服务端版本检查均为 `cloud-20261015`。
- GitHub 权限仅为 `contents: read` 和 `id-token: write`，无需个人访问令牌。检查步骤使用 GitHub 内置的临时 `github.token`。
- 工作流仅手动触发，没有 push / PR 触发器，没有 `--target-stage` 或部署作业。

GitHub 本次签发的 subject 带固定用户和仓库 ID，Bytebase 的名称模板需要改为上述精确值。身份具有在该项目创建和执行变更的能力；当前工作流只使用创建计划的路径。

## 演示 SQL

- 版本 1：等待 30 秒并创建独立表 `public.bytebase_release_order_demo_20261014`。
- 版本 2：给该演示表新增 `note` 字段。
- 版本 3：插入一条演示记录。
- 版本 4：创建独立表 `public.bytebase_release_mutex_demo_20261014` 并插入一条记录。
- 版本 5：仅执行 `SELECT pg_sleep(90)`，用于观察调度等待。

本次没有删除数据或修改业务表。该实验验证了当前 Cloud 上两个 Release 迁移任务的同库排队；不能据此推断所有普通 SQL 任务都会同库互斥。
