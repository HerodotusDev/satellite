pub mod state;
pub mod evm_fact_registry;
pub mod mmr_core;
pub mod receiver;
pub mod evm_growing;
pub mod utils;
// Main contract is in receiver.cairo file
// because L1 handlers cannot be defined in components

#[cfg(test)]
mod tests {
    use super::*;


    #[test]
    fn test() {
        let mut x = [1, 2, 3].span();
        assert(x.len() == 3, 'ERR_LEN');
        assert(*x.pop_front().unwrap() == 1, 'ERR_POP_FRONT');
        let mut y = array![];
        for i in x {
            y.append(*i);
        };
        assert(y.len() == 3, 'ERR_LEN');
    }
}
