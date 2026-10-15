-- Version 20261014000001: wait briefly so a second Release task can be queued.
SELECT pg_sleep(30);

CREATE TABLE public.bytebase_release_order_demo_20261014 (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY
);

COMMENT ON TABLE public.bytebase_release_order_demo_20261014
    IS 'Bytebase 多版本发布包顺序执行演示';
COMMENT ON COLUMN public.bytebase_release_order_demo_20261014.id
    IS '记录编号';
