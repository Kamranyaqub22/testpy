# TextField

Labelled text inputs with a floating label, helper text and an error state.

**Flutter:** `TextField` and `TextFormField` with `InputDecoration(labelText:, helperText:, errorText:)`. The theme supplies `radius-md`, `surface-raised` fill, `line` border, a 2px `brand` focus border and `negative` errors.

**The consumer provides:** a label that names the thing ("Sort code", not "Enter sort code"), the right keyboard type, and digit filters for numbers.

- Never insert separators while the user types: on the web it drops keystrokes. Show the formatted value as helper text instead (sort code "112233" → helper "11-22-33").
- Error messages say how to fix it: "Account numbers have 8 digits."
