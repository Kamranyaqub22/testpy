def parse_percentage(value):
    """Parse a percentage string and return it as a float."""
    try:
        if isinstance(value, str):
            value = value.strip().rstrip('%')
            return float(value) / 100.0
        return float(value)
    except ValueError:
        return None

def parse_float(value):
    """Parse a float from a string or return None if invalid."""
    try:
        return float(value)
    except ValueError:
        return None

def parse_int(value):
    """Parse an integer from a string or return None if invalid."""
    try:
        return int(value)
    except ValueError:
        return None

def parse_financial_data(data):
    """Parse financial data from a dictionary and return structured data."""
    return {
        'percentage': parse_percentage(data.get('percentage')),
        'amount': parse_float(data.get('amount')),
        'quantity': parse_int(data.get('quantity')),
    }