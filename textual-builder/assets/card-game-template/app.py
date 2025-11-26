"""
Card Game Template for Textual

A starter template for building turn-based card games with Textual.
Includes:
- Card widget with customizable suit, rank, and face-up/down state
- Hand container for displaying player hands
- Play area for cards in play
- Turn management system
- Action system with key bindings

Customize this template for your specific card game rules.
"""

from textual.app import App, ComposeResult
from textual.containers import Container, Horizontal, Vertical
from textual.widgets import Header, Footer, Label, Static
from textual.widget import Widget
from textual.reactive import reactive
from textual.message import Message
from textual.binding import Binding


class Card(Widget):
    """A playing card widget."""

    DEFAULT_CSS = """
    Card {
        width: 12;
        height: 10;
        border: round white;
        background: $panel;
        content-align: center middle;
    }

    Card:hover {
        background: $boost;
        border: heavy $primary;
    }

    Card.selected {
        border: double cyan;
        background: $accent;
    }

    Card.face-down {
        background: $surface;
        color: $text-muted;
    }

    Card.disabled {
        opacity: 0.5;
    }

    .card-rank {
        text-style: bold;
        text-align: center;
    }

    .card-suit {
        text-align: center;
    }
    """

    class Selected(Message):
        """Posted when card is selected."""

        def __init__(self, card: "Card") -> None:
            super().__init__()
            self.card = card

    class Played(Message):
        """Posted when card is played."""

        def __init__(self, card: "Card") -> None:
            super().__init__()
            self.card = card

    face_up = reactive(True)
    selectable = reactive(True)

    def __init__(
        self,
        rank: str,
        suit: str,
        value: int = 0,
        face_up: bool = True,
        card_id: str | None = None,
    ) -> None:
        super().__init__(id=card_id)
        self.rank = rank
        self.suit = suit
        self.value = value
        self.face_up = face_up

    def compose(self) -> ComposeResult:
        if self.face_up:
            yield Label(self.rank, classes="card-rank")
            yield Label(self.suit, classes="card-suit")
        else:
            yield Label("🂠", classes="card-back")

    def watch_face_up(self, face_up: bool) -> None:
        """Update display when card is flipped."""
        if face_up:
            self.remove_class("face-down")
        else:
            self.add_class("face-down")
        # Refresh the card content
        self.recompose()

    def on_click(self) -> None:
        """Handle card click."""
        if self.selectable:
            self.post_message(self.Selected(self))

    def flip(self) -> None:
        """Flip the card."""
        self.face_up = not self.face_up

    def play(self) -> None:
        """Play this card."""
        if self.selectable:
            self.post_message(self.Played(self))


class Hand(Container):
    """Container for a player's hand of cards."""

    DEFAULT_CSS = """
    Hand {
        layout: horizontal;
        height: auto;
        width: 100%;
        align: center middle;
    }

    Hand > Card {
        margin: 0 1;
    }
    """

    def __init__(self, player_name: str, **kwargs) -> None:
        super().__init__(**kwargs)
        self.player_name = player_name

    def add_card(self, card: Card) -> None:
        """Add a card to this hand."""
        self.mount(card)

    def remove_card(self, card: Card) -> None:
        """Remove a card from this hand."""
        card.remove()

    def get_cards(self) -> list[Card]:
        """Get all cards in this hand."""
        return list(self.query(Card))


class PlayArea(Container):
    """Central area where cards are played."""

    DEFAULT_CSS = """
    PlayArea {
        height: 1fr;
        border: round $primary;
        background: $surface;
        align: center middle;
    }

    PlayArea > .play-area-label {
        color: $text-muted;
    }
    """

    def compose(self) -> ComposeResult:
        yield Label("Play Area", classes="play-area-label")


class GameState(Static):
    """Display current game state."""

    DEFAULT_CSS = """
    GameState {
        dock: top;
        height: 3;
        background: $boost;
        content-align: center middle;
        text-style: bold;
    }
    """

    current_player = reactive("Player 1")
    turn = reactive(1)

    def render(self) -> str:
        return f"Turn {self.turn} | Current Player: {self.current_player}"


class CardGameApp(App):
    """A card game application."""

    CSS_PATH = "app.tcss"

    BINDINGS = [
        ("q", "quit", "Quit"),
        ("n", "next_turn", "Next Turn"),
        ("d", "draw_card", "Draw Card"),
        ("p", "play_selected", "Play Card"),
        Binding("space", "toggle_select", "Select/Deselect", show=True),
    ]

    selected_card: Card | None = None

    def compose(self) -> ComposeResult:
        """Create child widgets."""
        yield Header()
        yield GameState(id="game-state")

        with Vertical(id="game-container"):
            # Opponent's hand (face down)
            with Container(id="opponent-area"):
                yield Label("Opponent", id="opponent-label")
                yield Hand("Opponent", id="opponent-hand")

            # Play area
            yield PlayArea(id="play-area")

            # Player's hand (face up)
            with Container(id="player-area"):
                yield Hand("Player", id="player-hand")
                yield Label("Your Hand", id="player-label")

        yield Footer()

    def on_mount(self) -> None:
        """Initialize the game when app starts."""
        # Deal initial cards (example)
        player_hand = self.query_one("#player-hand", Hand)
        opponent_hand = self.query_one("#opponent-hand", Hand)

        # Example: Deal 5 cards to each player
        suits = ["♠", "♥", "♦", "♣"]
        ranks = ["A", "2", "3", "4", "5"]

        for i, rank in enumerate(ranks):
            # Player cards (face up)
            player_hand.add_card(Card(rank, suits[i % 4], face_up=True, card_id=f"player-{i}"))
            # Opponent cards (face down)
            opponent_hand.add_card(Card(rank, suits[i % 4], face_up=False, card_id=f"opp-{i}"))

    def on_card_selected(self, event: Card.Selected) -> None:
        """Handle card selection."""
        # Deselect previous
        if self.selected_card:
            self.selected_card.remove_class("selected")

        # Select new card
        self.selected_card = event.card
        event.card.add_class("selected")
        self.notify(f"Selected {event.card.rank} of {event.card.suit}")

    def on_card_played(self, event: Card.Played) -> None:
        """Handle card being played."""
        play_area = self.query_one("#play-area", PlayArea)
        card = event.card

        # Remove from hand
        hand = card.parent
        if isinstance(hand, Hand):
            hand.remove_card(card)

        # Move to play area
        play_area.mount(card)
        self.notify(f"Played {card.rank} of {card.suit}")

        # Deselect
        if self.selected_card == card:
            self.selected_card = None

    def action_next_turn(self) -> None:
        """Advance to next turn."""
        game_state = self.query_one(GameState)
        game_state.turn += 1

        # Toggle current player
        if game_state.current_player == "Player 1":
            game_state.current_player = "Player 2"
        else:
            game_state.current_player = "Player 1"

        self.notify(f"Turn {game_state.turn}")

    def action_draw_card(self) -> None:
        """Draw a card (example)."""
        player_hand = self.query_one("#player-hand", Hand)
        # Example: Draw a random card
        import random

        suits = ["♠", "♥", "♦", "♣"]
        ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"]

        card = Card(random.choice(ranks), random.choice(suits), face_up=True)
        player_hand.add_card(card)
        self.notify("Drew a card")

    def action_play_selected(self) -> None:
        """Play the currently selected card."""
        if self.selected_card:
            self.selected_card.play()
        else:
            self.notify("No card selected", severity="warning")

    def action_toggle_select(self) -> None:
        """Select/deselect hovered card."""
        # This is a simplified version - in practice you'd track the hovered card
        if self.selected_card:
            self.selected_card.remove_class("selected")
            self.selected_card = None


if __name__ == "__main__":
    app = CardGameApp()
    app.run()
