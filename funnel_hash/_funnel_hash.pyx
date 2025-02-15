# cython: language_level=3
"""
A funnel hash implementation written in Cython.

Inspired by the paper "Optimal Bounds for Open Addressing Without Reordering"
by Martin Farach-Colton, Andrew Krapivin, and William Kuszmaul.
https://arxiv.org/abs/2501.02305
"""

from libc.math cimport ceil, log2, pow, log

import random
from typing import Generator, Iterator


cdef int next_positive_random():
    return random.randint(0, 2**31 - 1)

cdef class _Entry:
    """
    An entry in the hash table. Represents a key-value pair. Should only be used internally.
    """

    cdef public object key
    cdef public object value
    cdef public bint occupied

    def __cinit__(self, object key = None, object value = None, bint occupied = False):
        self.key = key
        self.value = value
        self.occupied = occupied
    
    def __repr__(self) -> str:
        return f"_Entry(key={self.key!r}, value={self.value!r}, occupied={self.occupied!r})"

    def __str__(self) -> str:
        return repr(self)


# Used to indicate that no fallback value should be used for a key that does not exist.
cdef object _NO_FALLBACK = object()


cdef class FunnelHashTable:
    """
    A funnel hash table for storing key-value pairs.
    """

    cdef int capacity, num_inserts, special_occupancy, max_inserts
    cdef int alpha, beta, special_size, primary_size, special_salt

    cdef double delta

    cdef list[int] level_salts, level_bucket_counts
    cdef list[list[_Entry]] levels
    cdef list[_Entry] special_array

    def __init__(self, int capacity, object data = None, double delta = 0.1):
        """
        A funnel hash table for storing key-value pairs.

        Args:
            capacity (int): The capacity of the hash table (Note: this may not the number of key-value pairs, see `max_inserts`).
            data (list[tuple]): A list of key-value pairs to initialize the hash table with.
        """

        if capacity < 1:
            raise ValueError("Capacity must be at least 1.")
        if not (0 < delta < 1):
            raise ValueError("Delta must be between 0 and 1.")

        self.capacity = capacity
        self.delta = delta
        self.num_inserts = 0
        self.special_occupancy = 0

        self.max_inserts = capacity - int(delta * capacity)
        self.alpha = int(ceil(4 * log2(1 / delta) + 10))
        self.beta = int(ceil(2 * log2(1 / delta)))
        self.special_size = max(1, int(3 * delta * capacity / 4))
        self.primary_size = capacity - self.special_size

        self.level_bucket_counts = []
        self.level_salts = []
        self.levels = []
        self.special_array = []

        cdef int total_buckets = self.primary_size // self.beta
        cdef double a1 = total_buckets / (4 * (1 - pow(0.75, self.alpha))) if self.alpha > 0 else total_buckets

        cdef int remaining_buckets = total_buckets
        cdef int i, a_i
        for i in range(self.alpha):
            a_i = max(1, int(round(a1 * pow(0.75, i))))
            if remaining_buckets <= 0 or a_i <= 0:
                break
            a_i = min(a_i, remaining_buckets)
            self.level_bucket_counts.append(a_i)
            self.levels.append([_Entry() for _ in range(a_i * self.beta)])
            self.level_salts.append(next_positive_random())
            remaining_buckets -= a_i
        
        self.special_array = [_Entry() for _ in range(self.special_size)]
        self.special_salt = next_positive_random()

        if data is not None:
            if not isinstance(data, list):
                raise TypeError("Data must be a list of key-value pairs.")
            for key, value in data:
                self.insert(key, value)
    
    cdef int _hash(self, object key, int salt):
        cdef int hashed = hash(key) ^ salt
        return hashed & 0x7FFFFFFF

    cdef int _hash_level(self, object key, int level_index):
        return self._hash(key, self.level_salts[level_index])

    cdef int _hash_special(self, object key):
        return self._hash(key, self.special_salt)

    cpdef void insert(self, object key, object value):
        """
        Inserts the key-value pair into the hash table.
        Raises RuntimeError if the hash table is full.
        """

        if self.num_inserts >= self.max_inserts:
            raise RuntimeError("Hash table is full.")

        cdef int i, idx, start, end, bucket_index, j, size, probe_limit
        for i in range(len(self.levels)):
            bucket_index = self._hash_level(key, i) % self.level_bucket_counts[i]
            start = bucket_index * self.beta
            end = start + self.beta

            for idx in range(start, end):
                if not self.levels[i][idx].occupied or self.levels[i][idx].key == key:
                    self.levels[i][idx] = _Entry(key, value, True)
                    self.num_inserts += 1
                    return

        size = len(self.special_array)
        probe_limit = max(1, int(ceil(log(log(self.capacity + 1) + 1))))

        for j in range(probe_limit):
            idx = (self._hash_special(key) + j) % size
            if not self.special_array[idx].occupied or self.special_array[idx].key == key:
                self.special_array[idx] = _Entry(key, value, True)
                self.special_occupancy += 1
                self.num_inserts += 1
                return

        raise RuntimeError("Special array insertion failed; table is full.")

    cpdef object get(self, object key, object default_value = _NO_FALLBACK):
        """
        Returns the value associated with the key, or the default value if provided.
        If the key is not found and no default value is provided, raises KeyError.
        """

        cdef int i, idx, start, end, bucket_index, j, size, probe_limit
        for i in range(len(self.levels)):
            bucket_index = self._hash_level(key, i) % self.level_bucket_counts[i]
            start = bucket_index * self.beta
            end = start + self.beta

            for idx in range(start, end):
                if self.levels[i][idx].occupied and self.levels[i][idx].key == key:
                    return self.levels[i][idx].value

        size = len(self.special_array)
        probe_limit = max(1, int(ceil(log(log(self.capacity + 1) + 1))))

        for j in range(probe_limit):
            idx = (self._hash_special(key) + j) % size
            if self.special_array[idx].occupied and self.special_array[idx].key == key:
                return self.special_array[idx].value

        if default_value is _NO_FALLBACK:
            raise KeyError(f"{key}")
        else:
            return default_value
    
    def items(self) -> Generator[(object, object), None, None]:
        for level in self.levels:
            for _Entry in level:
                if _Entry.occupied:
                    yield _Entry.key, _Entry.value

        for _Entry in self.special_array:
            if _Entry.occupied:
                yield _Entry.key, _Entry.value
    
    def keys(self) -> Generator[object, None, None]:
        for _Entry in self.items():
            yield _Entry[0]
    
    def values(self) -> Generator[object, None, None]:
        for _Entry in self.items():
            yield _Entry[1]

    def __getitem__(self, key) -> object:
        return self.get(key)
    
    def __setitem__(self, key, value):
        self.insert(key, value)
    
    def __contains__(self, key) -> bool:
        try:
            self.get(key)
            return True
        except KeyError:
            return False
    
    def __len__(self) -> int:
        return self.num_inserts
    
    def __repr__(self) -> str:
        return f"FunnelHashTable(capacity={self.capacity}, data=[{', '.join(map(repr, self.items()))}], delta={self.delta})"
    
    def __str__(self) -> str:
        return repr(self)
    
    def __iter__(self) -> Iterator[object]:
        return iter(self.keys())
    
    def __delitem__(self, key):
        """
        Removes the key-value pair from the hash table.
        Raises KeyError if the key is not found.
        """

        cdef int i, idx, start, end, bucket_index, j, size, probe_limit
        for i in range(len(self.levels)):
            bucket_index = self._hash_level(key, i) % self.level_bucket_counts[i]
            start = bucket_index * self.beta
            end = start + self.beta

            for idx in range(start, end):
                if self.levels[i][idx].occupied and self.levels[i][idx].key == key:
                    self.levels[i][idx] = _Entry()
                    self.num_inserts -= 1
                    return

        size = len(self.special_array)
        probe_limit = max(1, int(ceil(log(log(self.capacity + 1) + 1))))

        for j in range(probe_limit):
            idx = (self._hash_special(key) + j) % size
            if self.special_array[idx].occupied and self.special_array[idx].key == key:
                self.special_array[idx] = _Entry()
                self.special_occupancy -= 1
                self.num_inserts -= 1
                return
        
        raise KeyError(f"{key}")
    
    def pop(self, key, default = _NO_FALLBACK) -> object:
        """
        Removes the key-value pair from the hash table and returns the value.
        If the key is not found and no default value is provided, raises KeyError.
        """

        try:
            value = self[key]
            del self[key]
            return value
        except KeyError as e:
            if default is _NO_FALLBACK:
                raise e
            else:
                return default
    
    def clear(self) -> None:
        """
        Clears the hash table.
        """

        keys = list(self.keys())
        for key in keys:
            del self[key]
    
    def print_internal_state(self) -> None:
        """
        Prints useful information about the internal state of the hash table.
        """

        print("=== Internal state for FunnelHashTable: ===")
        print(f"Capacity: {self.capacity}")
        print(f"Delta: {self.delta}")
        print(f"Num inserts: {self.num_inserts}")
        print(f"Special occupancy: {self.special_occupancy}")
        print(f"Max inserts: {self.max_inserts}")
        print(f"Level bucket counts: {self.level_bucket_counts}")
        print(f"Level salts: {self.level_salts}")
        print("=== Levels: ===")
        for i, level in enumerate(self.levels):
            print(f"Level {i+1}:", [entry if entry.occupied else None for entry in level])
        print("=== Special array: ===")
        print([entry if entry.occupied else None for entry in self.special_array])
