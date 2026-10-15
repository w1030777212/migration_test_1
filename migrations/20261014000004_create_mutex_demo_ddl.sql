-- Version 20261014000004: add this file for the second Release.
CREATE TABLE public.bytebase_release_mutex_demo_20261014 (
    id INTEGER PRIMARY KEY,
    executed_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);

COMMENT ON TABLE public.bytebase_release_mutex_demo_20261014
    IS 'Bytebase 同库发布包任务互斥演示';
COMMENT ON COLUMN public.bytebase_release_mutex_demo_20261014.id
    IS '演示记录编号';
COMMENT ON COLUMN public.bytebase_release_mutex_demo_20261014.executed_at
    IS '第二个发布包实际执行时间';

INSERT INTO public.bytebase_release_mutex_demo_20261014 (id) VALUES (1);
