from setuptools import setup
from setuptools import find_packages

required = [
    "mock",
    "numpy",
    "pandas",
    "pydocstyle",
    "pytest",
    "pytest-cov",
    "pylint==2.8.3",
    "delphi-utils",
    "freezegun",
    "pandas-gbq"
]

setup(
    name="delphi_google_symptoms",
    version="0.0.1",
    description="Indicators from Google Research's Open COVID-19 Data project",
    author="",
    author_email="",
    url="https://github.com/cmu-delphi/covidcast-indicators",
    install_requires=required,
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "Programming Language :: Python :: 3.8",
    ],
    packages=find_packages(),
)
