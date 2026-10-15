-- Version 20261014000002: requires the table from the previous version.
ALTER TABLE public.bytebase_release_order_demo_20261014
    ADD COLUMN note VARCHAR(255) NOT NULL DEFAULT '';

COMMENT ON COLUMN public.bytebase_release_order_demo_20261014.note
    IS '演示备注';
