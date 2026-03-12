def parse_percentage(value):
    """
    Parse input into a percentage float.
    Accepts numeric types or strings like "5", "5%", "0.05".
    Returns a float representing percent (e.g. 5.0) or None on invalid input.
    """
    if value is None:
        return None
    try:
        # accept numeric inputs directly
        if isinstance(value, (int, float)):
            parsed = float(value)
        else:
            s = str(value).strip()
            if s.endswith('%'):
                s = s[:-1].strip()
            parsed = float(s)
        # if the user provided a fraction (<= 1), convert to percent
        if abs(parsed) <= 1.0:
            parsed = parsed * 100.0
        return parsed
    except (ValueError, TypeError):
        return None

def calculate_fee_override(original_fee, new_fee):
    if new_fee is not None:
        return new_fee
    return original_fee

def reset_fee_override(fee_overrides, col_key):
    if col_key in fee_overrides:
        del fee_overrides[col_key]
    return fee_overrides

def handle_fee_input(fee_overrides, col_key, input_value, original_fee):
    """
    Parse input_value into a percentage and update fee_overrides[col_key].
    original_fee is expected to be a percentage (e.g. 5.0).
    If parsed value equals original_fee (within a small tolerance), remove the override.
    """
    parsed_value = parse_percentage(input_value)
    if parsed_value is not None and abs(parsed_value - (original_fee or 0.0)) > 1e-8:
        fee_overrides[col_key] = parsed_value
    else:
        reset_fee_override(fee_overrides, col_key)
    return fee_overrides

def manage_manual_settings(manual_settings, col_key, rolled_months=None, deferred_pct=None):
    """
    Ensure manual_settings[col_key] exists.
    Validate rolled_months (cast to int if possible).
    Parse deferred_pct into percentage using parse_percentage.
    """
    if col_key not in manual_settings:
        manual_settings[col_key] = {}

    if rolled_months is not None:
        try:
            manual_settings[col_key]['rolledMonths'] = int(rolled_months)
        except (ValueError, TypeError):
            # ignore invalid rolled_months (no change)
            pass

    if deferred_pct is not None:
        parsed = parse_percentage(deferred_pct)
        if parsed is not None:
            manual_settings[col_key]['deferredPct'] = parsed

    return manual_settings