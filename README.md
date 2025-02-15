# Funnel Hash Cython Implementation

A Cython implementation of the funnel hash data structure, inspired by the paper "[Optimal Bounds for Open Addressing Without Reordering](https://arxiv.org/abs/2501.02305)" by Martin Farach-Colton, Andrew Krapivin, and William Kuszmaul.

## Building

To build the extension, run the following commands:

```bash
pip install -r requirements.txt
python setup.py build_ext --inplace
```

## Usage

Import and initialize the `FunnelHashTable`:

```python
from funnel_hash import FunnelHashTable

table = FunnelHashTable(capacity=30)
```

### Inserting and Retrieving Key-Value Pairs

```python
table['foo'] = 1
table['bar'] = 2

value = table['foo']

print(value) # 1
print('bar' in table) # True
```

### Inspecting Internal State

Use `print_internal_state()` to visualize the table’s internal structure, which is helpful for debugging and understanding the hashing process.

```python
table.print_internal_state()
# === Internal state for FunnelHashTable: ===
# Capacity: 30
# Delta: 0.1
# Num inserts: 2
# Special occupancy: 0
# Max inserts: 27
# Level bucket counts: [1, 1, 1, 1]
# Level salts: [1306425610, 470756312, 141368734, 2060733548]
# === Levels: ===
# Level 1: [_Entry(key='foo', value=1, occupied=True), _Entry(key='bar', value=2, occupied=True), None, None, None, None, None]
# Level 2: [None, None, None, None, None, None, None]
# Level 3: [None, None, None, None, None, None, None]
# Level 4: [None, None, None, None, None, None, None]
# === Special array: ===
# [None, None]
```

## Tests

A few tests are included in the [`tests`](tests) directory to verify the correctness of the implementation. You can run the tests using the unittest module:

```bash
python -m unittest discover -s tests
```

## Notes

This implementation is designed to illustrate the Funnel Hash algorithm and is optimized for learning purposes rather than raw performance. For most use cases, Python’s built-in dictionary remains the fastest option.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file.

## Acknowledgments

This project builds on the C++ implementation by [ascv0228](https://github.com/ascv0228/elastic-funnel-hashing).
