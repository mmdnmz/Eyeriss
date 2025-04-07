# Eyeriss‑V1 CNN Hardware Accelerator (Verilog)

This repository hosts the complete Verilog source code for a fully functioning CNN hardware accelerator based on the [Eyeriss‑V1](https://eyeriss.mit.edu/) architecture. Eyeriss‑V1 is a pioneering, energy‑efficient accelerator design that implements a row‑stationary dataflow to optimize data movement and maximize reuse during deep neural network processing.

## Overview

- **Efficient Dataflow:** Implements the row‑stationary dataflow to exploit convolutional, filter, and ifmap reuse, reducing costly off‑chip memory accesses.
- **High Energy Efficiency:** Designed to minimize data movement energy and improve throughput for CNN inference.
- **Complete Design:** Includes all Verilog sources, simulation testbenches, and documentation necessary to synthesize and verify the accelerator.

## Repository Structure

- **/src**: Verilog source files for the accelerator.
- **/sim**: Simulation testbenches and scripts.
- **/docs**: User guides, documentation, and design notes.
- **/images**: Official images of the Eyeriss‑V1 architecture and chip die.

## Official Eyeriss‑V1 Images

Below are the official images from the Eyeriss project:

![Eyeriss Architecture](images/eyeriss_architecture.png)
*Figure 1: Eyeriss‑V1 Architecture Overview*

![Chip Die Photo](images/eyeriss_die_photo.png)
*Figure 2: Eyeriss‑V1 Chip Die Photo*

*Note: These images are provided for reference and are sourced from the original Eyeriss project at MIT.*

## Getting Started

1. **Clone the Repository:**
   ```bash
   git clone https://github.com/your_username/eyeriss-v1-accelerator.git
   cd eyeriss-v1-accelerator
