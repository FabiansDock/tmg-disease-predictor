from setuptools import find_packages, setup

setup(
    name="Flask Disease Predictor",
    version="0.0.1",
    author="fabian",
    author_email="romanreigns397@gmail.com",
    install_requires=['torch', 'torchvision', 'flask', 'matplotlib', 'requests'],
    packages=find_packages()
)