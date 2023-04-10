---
name: Accessing Vector Index
severity: warning

---

When accessing an index of a `Vec` type, its recommended to use the `.get(index)` function versus an index access.
An index access will cause the application to panic if the index does not exist.

## Resources

- [Rust Vector Indexing]

[Rust Vector Indexing]: https://doc.rust-lang.org/std/vec/struct.Vec.html#indexing
