from datetime import datetime

BROADCAST_DURATION = 60   # seconds per attempt
PAUSE_DURATION = 10       # seconds between attempts
MAX_ATTEMPTS = 5
CYCLE = BROADCAST_DURATION + PAUSE_DURATION  # 70 s


def compute_broadcast_state(order):
    """Return broadcast state dict for an en_attente order."""
    elapsed = (datetime.utcnow() - order.created_at).total_seconds()
    cycle_index = int(elapsed // CYCLE)

    if cycle_index >= MAX_ATTEMPTS:
        return {
            'expired': True,
            'attempt': MAX_ATTEMPTS,
            'broadcasting': False,
            'seconds_remaining': 0,
        }

    position = elapsed % CYCLE
    broadcasting = position < BROADCAST_DURATION
    if broadcasting:
        seconds_remaining = max(0, int(BROADCAST_DURATION - position))
    else:
        seconds_remaining = max(0, int(PAUSE_DURATION - (position - BROADCAST_DURATION)))

    return {
        'expired': False,
        'attempt': cycle_index + 1,
        'broadcasting': broadcasting,
        'seconds_remaining': seconds_remaining,
    }


def is_in_broadcast_window(order):
    """True only if the order is currently being broadcast (not pausing, not expired)."""
    state = compute_broadcast_state(order)
    return not state['expired'] and state['broadcasting']
