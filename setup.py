from Cython.Build import cythonize
from setuptools import setup, Extension

ext_modules = [
    Extension(
        "funnel_hash._funnel_hash",
        sources=["funnel_hash/_funnel_hash.pyx"],
        extra_compile_args=["-O3"],
    )
]

setup(
    ext_modules=cythonize(ext_modules),
)
