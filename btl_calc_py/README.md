# BTL Calculation Project

This project implements various calculations related to Buy-to-Let (BTL) properties, including fee management, rate handling, and effective financial metrics.

## Project Structure

```
btl_calc_py
├── src
│   └── btl_calc
│       ├── __init__.py
│       ├── calculations.py
│       ├── fees.py
│       ├── rates.py
│       ├── parsers.py
│       ├── utils.py
│       └── cli.py
├── tests
│   ├── test_calculations.py
│   ├── test_fees.py
│   └── test_rates.py
├── docs
│   └── architecture.md
├── pyproject.toml
├── setup.cfg
├── requirements.txt
├── .gitignore
└── README.md
```

## Installation

To install the required dependencies, run:

```
pip install -r requirements.txt
```

## Usage

You can use the command-line interface to perform BTL calculations. Run the following command to see available options:

```
python -m btl_calc.cli
```

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue for any suggestions or improvements.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.