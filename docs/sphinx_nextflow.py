#!/usr/bin/env python3

from docutils import nodes 
from docutils.parsers.rst.roles import set_classes
import sphinx
import sphinx.addnodes

def setup(app):
    """Install the plugin.

    :param app: Sphinx application context.
    """
    app.add_role('param', param_role)
    app.add_role('cl_param', cl_param_role)
    app.add_role('config_param', config_param_role)
    app.add_role('flag_param', param_role)
    app.add_role('obj', obj_role)
    #app.add_object_type('param', 'param')

    return

def param_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """Role for a Nextflow Param desription.
    Returns 2 part tuple containing list of nodes to insert into the
    document and a list of system messages.  Both are allowed to be
    empty.

    :param name: The role name used in the document.
    :param rawtext: The entire markup snippet, with role.
    :param text: The text marked with the role.
    :param lineno: The line number where rawtext appears in the input.
    :param inliner: The inliner instance that called us.
    :param options: Directive options for customization.
    :param content: The directive content for customization.
    """
    try:
        #error condition
        pass
    except ValueError:
        msg = inliner.reporter.error('invalid_param: ' + text, line=lineno)
        prb = inliner.problematic(rawtext, rawtext, msg)
        return [prb], [msg]
   
    param_split = text.split()
    param = param_split[0].strip(' -')
    arg   = ' '.join(param_split[1:])

    app = inliner.document.settings.env.app
    #print(app)
    #print(inliner.document.settings.env)
    #print(inliner.document.settings)
    node = make_param_node(rawtext, param, arg, '', '', app, options)
    return [node], []

def cl_param_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """Role for a Nextflow Param desription.
    Returns 2 part tuple containing list of nodes to insert into the
    document and a list of system messages.  Both are allowed to be
    empty.

    :param name: The role name used in the document.
    :param rawtext: The entire markup snippet, with role.
    :param text: The text marked with the role.
    :param lineno: The line number where rawtext appears in the input.
    :param inliner: The inliner instance that called us.
    :param options: Directive options for customization.
    :param content: The directive content for customization.
    """
    try:
        #error condition
        pass
    except ValueError:
        msg = inliner.reporter.error('invalid_param: ' + text, line=lineno)
        prb = inliner.problematic(rawtext, rawtext, msg)
        return [prb], [msg]
   
    param_split = text.split()
    param = param_split[0].strip(' -')
    arg   = ' '.join(param_split[1:])

    app = inliner.document.settings.env.app
    #print(app)
    #print(inliner.document.settings.env)
    #print(inliner.document.settings)
    node = make_param_node(rawtext, param, arg, 'cl_only', '', app, options)
    return [node], []

def config_param_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """Role for a Nextflow Param desription.
    Returns 2 part tuple containing list of nodes to insert into the
    document and a list of system messages.  Both are allowed to be
    empty.

    :param name: The role name used in the document.
    :param rawtext: The entire markup snippet, with role.
    :param text: The text marked with the role.
    :param lineno: The line number where rawtext appears in the input.
    :param inliner: The inliner instance that called us.
    :param options: Directive options for customization.
    :param content: The directive content for customization.
    """
    try:
        #error condition
        pass
    except ValueError:
        msg = inliner.reporter.error('invalid_param: ' + text, line=lineno)
        prb = inliner.problematic(rawtext, rawtext, msg)
        return [prb], [msg]
   
    param_split = text.split()
    param = param_split[0].strip(' -')
    arg   = ' '.join(param_split[1:])

    app = inliner.document.settings.env.app
    #print(app)
    #print(inliner.document.settings.env)
    #print(inliner.document.settings)
    node = make_param_node(rawtext, param, arg, 'param_only', '', app, options)
    return [node], []


def make_param_node(rawtext, param, arg, mode, param_type, app, options):
    """Dummy return text node.Create a link to a BitBucket resource.

    :param rawtext: Text being replaced with link node.
    :param param: Relevent Parameter
    :param arg" Arguments
    :param options: Options dictionary passed to role func.
    """
    #print(rawtext, param, arg, mode, param_type, app, options)
    set_classes(options)
    cl_string = ''
    param_string = ''
    if param_type == 'flag':
        cl_string = '--' + param
        param_string = "(params.%s = true)" % (param, param)
    elif arg:
        cl_string = '--%s %s' % (param, arg)
        use_arg = arg.strip('"').strip("'")
        if (not use_arg.startswith('[') 
            and not use_arg in ['true', 'false']):
            use_arg = '"%s"' % use_arg
        param_string = '(params.%s = %s)' % (param, use_arg)
    else:
        cl_string = '--' + param
        param_string = '(params.%s)' % (param)
    
    if mode == 'cl_only':
        out_text = cl_string
    elif mode == 'param_only':
        out_text = param_string.strip('( )')
    else:
        out_text = cl_string + ' ' + param_string 
 
    node = nodes.literal(rawtext, out_text)
    #node = sphinx.addnodes.literal_strong(rawtext, out_text)
    #node = sphinx.addnodes.desc_parameter(rawtext, out_text, **options)
    #node = sphinx.addnodes.desc_name(rawtext, out_text, **options)
    #node = nodes.reference(rawtext,  out_text, #refuri=ref,
    #                           **options)
    return node


def obj_role(name, rawtext, text, lineno, inliner, options={}, content=[]):
    """Role for a Nextflow Generic Object.
    Returns 2 part tuple containing list of nodes to insert into the
    document and a list of system messages.  Both are allowed to be
    empty.

    :param name: The role name used in the document.
    :param rawtext: The entire markup snippet, with role.
    :param text: The text marked with the role.
    :param lineno: The line number where rawtext appears in the input.
    :param inliner: The inliner instance that called us.
    :param options: Directive options for customization.
    :param content: The directive content for customization.
    """
    app = inliner.document.settings.env.app
    node = nodes.literal(rawtext, text)
    return [node], []
