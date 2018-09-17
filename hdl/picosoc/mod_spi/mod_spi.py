
def generate_c_code(icosoc_h, icosoc_c, mod):
    code = """
static inline void icosoc_@name@_cs(uint32_t bitmask) {
    *(volatile uint32_t*)(0x20000004 + @addr@ * 0x10000) = bitmask;
}

static inline uint32_t icosoc_@name@_getcs() {
    return *(volatile uint32_t*)(0x20000004 + @addr@ * 0x10000);
}

static inline uint8_t icosoc_@name@_xfer(uint8_t value) {
    *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000) = value;
    return *(volatile uint32_t*)(0x20000008 + @addr@ * 0x10000);
}

static inline void icosoc_@name@_prescale(uint32_t value) {
    *(volatile uint32_t*)(0x20000000 + @addr@ * 0x10000) = value;
}

static inline void icosoc_@name@_mode(bool cpol, bool cpha) {
    *(volatile uint32_t*)(0x2000000c + @addr@ * 0x10000) = (cpol ? 1 : 0) | (cpha ? 2 : 0);
}
"""

    code = code.replace("@name@", mod["name"])
    code = code.replace("@addr@", mod["addr"])
    icosoc_h.append(code)

