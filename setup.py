from setuptools import setup, find_packages, Extension
import versioneer
import sys
import os

# mako_templates=[(os.path.join('cydatemap', 'cydatemap.mako.pyx'), os.path.join('cydatemap', 'cydatemap.pyx')),
#                       (os.path.join('cydatemap', 'cydatemap.mako.pxd'), os.path.join('cydatemap', 'cydatemap.pxd'))]
# 
# if '--makoize' in sys.argv:
#     del sys.argv[sys.argv.index('--makoize')]
#     lookup = TemplateLookup(directories = ['.'])
#     for template_file, target_file in mako_templates:
#         template = lookup.get_template(template_file)
#         with open(target_file, 'w') as outfile:
#             outfile.write(template.render())

# Determine whether to use Cython
if '--cythonize' in sys.argv:
    from Cython.Build.Dependencies import cythonize
    from Cython.Distutils import build_ext
    cythonize_switch = True
    del sys.argv[sys.argv.index('--cythonize')]
    ext = 'pyx'
    directives = {}
    directives['linetrace'] = False
    directives['binding'] = False
    directives['profile'] = False
    cmdclass = {'build_ext': build_ext}
else:
    from setuptools.command.build_ext import build_ext  # @NoMove @Reimport
    cythonize_switch = False
    ext = 'c'
    cmdclass = {'build_ext': build_ext}

ext_modules = [Extension('cydatemap.cydatemap', 
                         [os.path.join('cydatemap', 
                                       'cydatemap.%s' % ext)])]


setup(name='cydatemap',
      version=versioneer.get_version(),
      cmdclass=versioneer.get_cmdclass(cmdclass),
      author='Jason Rudy',
      author_email='jcrudy@gmail.com',
      url='https://github.com/jcrudy/cydatemap',
      packages=find_packages(),
      package_data={'cydatemap': ['cydatemap.pxd', 'cydatemap.pyx']},
      ext_modules = cythonize(ext_modules, compiler_directives=directives) if cythonize_switch else ext_modules,
      install_requires=[]
     )