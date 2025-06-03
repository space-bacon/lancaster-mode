from setuptools import setup, find_packages

setup(
    name='lancaster_mode',
    version='0.1.0',
    author='Dr. James Burton Lancaster',
    author_email='burton@burtonlancaster.com',
    description='Symbolic recursion engine for semiotic compression and NP-horizon modeling',
    long_description=open('README.md').read(),
    long_description_content_type='text/markdown',
    url='https://github.com/space-bacon/lancaster-mode',
    packages=find_packages(),
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Science/Research',
        'Topic :: Scientific/Engineering :: Artificial Intelligence',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.8',
        'Operating System :: OS Independent',
    ],
    license='MIT',
    python_requires='>=3.7',
    install_requires=[],
)
