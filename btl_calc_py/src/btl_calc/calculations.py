def calculate_effective_rate(proc_fee_pct, broker_fee_pct, broker_fee_flat):
    """
    Calculate the effective rate based on the processing fee percentage,
    broker fee percentage, and broker fee flat amount.
    """
    effective_rate = proc_fee_pct + broker_fee_pct + (broker_fee_flat / 100)
    return effective_rate


def calculate_total_fees(fee_overrides, manual_settings):
    """
    Calculate the total fees based on fee overrides and manual settings.
    """
    total_fees = sum(fee_overrides.values())
    for setting in manual_settings.values():
        total_fees += setting.get('rolledMonths', 0) + setting.get('deferredPct', 0)
    return total_fees


def calculate_final_amount(base_amount, total_fees):
    """
    Calculate the final amount after applying total fees to the base amount.
    """
    final_amount = base_amount - total_fees
    return final_amount


def parse_and_validate_percentage(value):
    """
    Parse a percentage value and validate it.
    Returns the percentage as a decimal if valid, otherwise raises a ValueError.
    """
    parsed_value = float(value.strip('%')) / 100
    if parsed_value < 0 or parsed_value > 1:
        raise ValueError("Percentage must be between 0 and 100.")
    return parsed_value


def calculate_fee_overrides(fee_inputs, original_fees):
    """
    Calculate fee overrides based on input values and original fees.
    """
    fee_overrides = {}
    for key, input_value in fee_inputs.items():
        if input_value is not None:
            parsed_value = parse_and_validate_percentage(input_value)
            if abs(parsed_value - original_fees.get(key, 0)) > 1e-8:
                fee_overrides[key] = parsed_value * 100
    return fee_overrides