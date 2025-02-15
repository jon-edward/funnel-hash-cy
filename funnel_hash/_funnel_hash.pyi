"""
A funnel hash implementation written in Cython.

Inspired by the paper "Optimal Bounds for Open Addressing Without Reordering"
by Martin Farach-Colton, Andrew Krapivin, and William Kuszmaul.
https://arxiv.org/abs/2501.02305

Based on the C++ implementation by ascv0228.
https://github.com/ascv0228/elastic-funnel-hashing
"""

from typing import Generator, Mapping

class FunnelHashTable(Mapping):
    """
    A funnel hash table for storing key-value pairs.
    """

    def __init__(self, capacity: int, data=None, delta: float = 0.1):
        """
        A funnel hash table for storing key-value pairs.

        Args:
            capacity (int): The capacity of the hash table (Note: this may not the number of key-value pairs, see `max_inserts`).
            data (list[tuple]): A list of key-value pairs to initialize the hash table with.
        """

    def __contains__(self, key, /):
        """Return bool(key in self)."""

    def __delitem__(*args, **kwargs):
        """
        Removes the key-value pair from the hash table.
        Raises KeyError if the key is not found.
        """

    def __getitem__(self, key, /):
        """Return self[key]."""

    def __iter__(self, /):
        """Implement iter(self)."""

    def __len__(self, /):
        """Return len(self)."""

    def __setitem__(self, key, value, /):
        """Set self[key] to value."""

    def clear(self) -> None:
        """
        Clears the hash table.
        """

    def get(self, key, default_value=...):
        """
        Returns the value associated with the key, or the default value if provided.
        If the key is not found and no default value is provided, raises KeyError.
        """

    def insert(self, key, value) -> None:
        """
        Inserts the key-value pair into the hash table.
        Raises RuntimeError if the hash table is full.
        """

    def items(self) -> Generator[(object, object), None, None]: ...
    def keys(self) -> Generator[object, None, None]: ...
    def pop(self, key, default=...) -> object:
        """
        Removes the key-value pair from the hash table and returns the value.
        If the key is not found and no default value is provided, raises KeyError.
        """

    def print_internal_state(self) -> None:
        """
        Prints useful information about the internal state of the hash table.
        """

    def values(self) -> Generator[object, None, None]: ...
