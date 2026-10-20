# PasscodeEntry

Six dots and a number pad for creating, confirming and entering the passcode. It shakes on a wrong code.

**Flutter:** `PasscodeEntry(title: 'Approve payment', subtitle: '£42.50 to Jonathan Smith', onCompleted: (code) => ok ? null : 'Wrong passcode')`. For a sensitive action mid-flow, use `confirmWithPasscode(context, title: …)`, which opens it in a sheet.

**The consumer provides:** a title that names the action, an optional subtitle with the amount or reason, and `onCompleted`, which returns null to accept or an error to shake and clear.

- Dots are 16px: filled `brand` when entered, outlined `ink-muted` when empty, all `negative` on error.
- Ask for the passcode before showing card details or the PIN, approving a payment, and changing the passcode.
