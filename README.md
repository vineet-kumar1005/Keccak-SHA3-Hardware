Verilog implementation of the Keccak-f[1600] permutation and SHA-3 family cryptographic primitives.

## Features

* Keccak-f[1600] permutation core
* SHA3-256 hash function
* SHA3-512 hash function
* SHAKE128 extendable-output function (XOF)
* SHAKE256 extendable-output function (XOF)
* Modular and reusable hardware architecture
* Verilog HDL implementation

## Directory Structure

```text
Keccak-SHA3-Hardware/
├── rtl/
│   ├── keccak/
│   ├── sha3_256/
│   ├── sha3_512/
│   ├── shake128/
│   └── shake256/
│
├── docs/
│   └── NIST.FIPS.202.pdf
│
├── README.md
└── .gitignore
```

## References

* FIPS 202: SHA-3 Standard – Permutation-Based Hash and Extendable-Output Functions
* Keccak Team Documentation

## Future Work

* NIST Known Answer Test (KAT) verification
* FPGA synthesis and resource utilization analysis
* Performance optimization and throughput evaluation
* Integration with post-quantum cryptographic schemes such as ML-KEM

## Author

Vineet Kumar
