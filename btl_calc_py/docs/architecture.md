# Architecture of BTL Calculation Project

## Overview
The BTL Calculation project is designed to provide a comprehensive solution for managing Buy-to-Let (BTL) financial calculations. The project is structured to facilitate easy maintenance, testing, and expansion of features related to BTL calculations, fees, and rates.

## Project Structure
The project is organized into several key components:

- **src/btl_calc**: This directory contains the core functionality of the BTL calculations.
  - **`__init__.py`**: Initializes the btl_calc package.
  - **calculations.py**: Implements various BTL calculations, including effective rates and total fees.
  - **fees.py**: Manages fee calculations, including overrides and manual settings.
  - **rates.py**: Handles rate inputs and management of rate overrides.
  - **parsers.py**: Provides utility functions for parsing financial data formats.
  - **utils.py**: Contains general utility functions for validation and formatting.
  - **cli.py**: Implements a command-line interface for user interaction.

- **tests**: This directory contains unit tests for the project.
  - **test_calculations.py**: Tests for the functions in calculations.py.
  - **test_fees.py**: Tests for the functions in fees.py.
  - **test_rates.py**: Tests for the functions in rates.py.

- **docs**: Contains documentation files, including architecture and usage guides.

- **pyproject.toml**: Configuration file for project metadata and dependencies.

- **setup.cfg**: Configuration settings for packaging and distribution.

- **requirements.txt**: Lists the dependencies required for the project.

- **.gitignore**: Specifies files and directories to be ignored by version control.

- **README.md**: Provides an overview of the project, installation instructions, and usage examples.

## Key Components

### Calculations
The calculations module is responsible for performing essential BTL financial metrics, such as:
- Effective rates calculation
- Total fees calculation
- Other financial metrics relevant to BTL investments

### Fees Management
The fees module manages various fee structures, including:
- Calculation of fees based on user input
- Handling of fee overrides and manual settings

### Rate Management
The rates module focuses on:
- Input handling for various rates
- Parsing and managing rate overrides

### Input Parsing
The parsers module provides utility functions to ensure that user inputs are correctly formatted and validated, particularly for financial data such as percentages.

### Utilities
The utils module contains helper functions that are used across the project, ensuring code reusability and maintainability.

### Command-Line Interface
The CLI module allows users to interact with the BTL calculations directly from the terminal, providing a user-friendly way to perform calculations without needing a graphical interface.

## Conclusion
This architecture provides a clear separation of concerns, making it easier to manage, test, and extend the BTL Calculation project. Each module is designed to handle specific aspects of the calculations, ensuring that the project remains organized and maintainable.