# Card Game Template

A starter template for building turn-based card games with Textual.

## Features

- **Card Widget**: Customizable playing cards with suit, rank, face-up/down state
- **Hand Container**: Display and manage player hands
- **Play Area**: Central area for cards in play
- **Turn System**: Basic turn management
- **Interactivity**: Card selection and playing with keyboard shortcuts

## Running the Template

```bash
python app.py
```

## Key Bindings

- `d` - Draw a card
- `space` - Select/deselect card
- `p` - Play selected card
- `n` - Next turn
- `q` - Quit

## Customization

### Card Values

Modify the `Card` class to add game-specific properties:

```python
class Card(Widget):
    def __init__(self, rank: str, suit: str, power: int = 0, special_ability: str = ""):
        self.power = power
        self.special_ability = special_ability
        # ...
```

### Game Rules

Implement game logic in the `CardGameApp` methods:
- `on_card_played()` - Validate and process card plays
- `action_draw_card()` - Implement deck management
- `action_next_turn()` - Add turn-based game logic

### Card Appearance

Edit `Card.compose()` or the CSS in `app.tcss` to change card styling.

### Deck Management

Add a `Deck` class to manage card shuffling and drawing:

```python
class Deck:
    def __init__(self):
        self.cards = []
        self.shuffle()

    def shuffle(self):
        import random
        random.shuffle(self.cards)

    def draw(self) -> Card | None:
        return self.cards.pop() if self.cards else None
```

## Structure

```
card-game-template/
├── app.py          # Main application
├── app.tcss        # Styles
└── README.md       # This file
```
