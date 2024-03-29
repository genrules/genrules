def _run_if(ctx):
    executable = ctx.actions.declare_file(ctx.label.name + ".sh")
    cmd = ""
    if ctx.attr.not_empty: # todo support else
        cmd = """
            if [ -n "{c}" ]
            then
                bash {t}
            fi
        """.format(
            c = ctx.attr.not_empty, 
            t = _maybe_path(ctx.attr.then_run),
            e = _maybe_path(ctx.attr.else_run))
    if ctx.attr.succeeds:
        cmd = "(bash {s} && bash {t}) || (bash {e})".format(
            s = _maybe_path(ctx.attr.succeeds), 
            t = _maybe_path(ctx.attr.then_run),
            e = _maybe_path(ctx.attr.else_run),
        )
    if ctx.attr.fails:
        cmd = "(bash {s} || bash {t})".format(
            s = _maybe_path(ctx.attr.fails), 
            t = _maybe_path(ctx.attr.then_run),
        )
    if ctx.attr.equals:
        cmd = """
            if [ $(bash {e}) = "{v}" ]
            then
                bash {t}
            fi
        """.format(
            e = _maybe_path(ctx.attr.equals), 
            t = _maybe_path(ctx.attr.then_run),
            v = ctx.attr.value)
    cmd = ctx.expand_location(cmd)
    ctx.actions.write(executable, cmd, is_executable=True)
    return [DefaultInfo(
            files = depset([executable], transitive = [
                _maybe_files(ctx.attr.then_run),
                _maybe_files(ctx.attr.else_run),
                _maybe_files(ctx.attr.fails),
                _maybe_files(ctx.attr.succeeds),
            ]),
            executable = executable,
            runfiles = ctx.runfiles(
                _maybe_file_list(ctx.attr.then_run)+
                _maybe_file_list(ctx.attr.else_run)+
                _maybe_file_list(ctx.attr.fails)+
                _maybe_file_list(ctx.attr.equals)+
                _maybe_file_list(ctx.attr.succeeds))
        )]

def _maybe_path(attribute):
    return attribute.files.to_list().pop().short_path if attribute else ""

def _maybe_files(attribute):
    return attribute.files if attribute else depset()

def _maybe_file_list(attribute):
    return attribute.files.to_list() + attribute[DefaultInfo].default_runfiles.files.to_list() if attribute else []

run_if = rule(
    _run_if,
    attrs = {
        "not_empty": attr.string(),
        "succeeds": attr.label(),
        "fails": attr.label(),
        "equals": attr.label(),
        "value": attr.string(),
        "then_run": attr.label(),
        "else_run": attr.label(),
    },
    executable = True,
)
