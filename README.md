# Keccak-Verilog

Verilog implementation of the Keccak-f[1600] permutation used in SHA-3.

## Features
- Theta step
- Rho step
- Pi step
- Chi step
- Iota step
- Round function
- Top-level permutation module

## Directory Structure

```text
Keccak-Verilog/
├── rtl/
│   ├── keccak_theta.v
│   ├── keccak_rho.v
│   ├── keccak_pi.v
│   ├── keccak_chi.v
│   ├── keccak_iota.v
│   ├── keccak_round.v
│   └── keccak_permutation.v
│
├── docs/
│   └── NIST.FIPS.202.pdf
│
├── README.md
└── .gitignore
```

## Tools Used
- Verilog HDL
- Icarus Verilog


## Future Work

- Implement SHA3-256 and SHA3-512 using the Keccak-f[1600] core.
- Implement SHAKE128 and SHAKE256 extendable-output functions (XOFs).
- Add support for streaming message absorption and squeezing.
