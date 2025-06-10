pub mod header_rlp_index {
    pub const PARENT_HASH: usize = 0;
    pub const STATE_ROOT: usize = 3;
    pub const BLOCK_NUMBER: usize = 8;
    pub const TIMESTAMP: usize = 11;
}

pub mod decoders {
    use cairo_lib::{
        encoding::rlp::{rlp_decode_list_lazy, RLPItem},
        utils::{types::words64::{Words64, Words64Trait, reverse_endianness_u64}},
    };

    pub fn decode_rlp(input: Words64, lazy: Span<usize>) -> (Span<(Words64, usize)>, usize) {
        match rlp_decode_list_lazy(input, lazy) {
            Result::Err(_) => panic!("ERR_DECODE_RLP_RESULT"),
            Result::Ok((
                decoded_rlp, decoded_rlp_len,
            )) => {
                match decoded_rlp {
                    RLPItem::Bytes(_) => panic!("ERR_DECODE_RLP_BYTES"),
                    RLPItem::List(l) => {
                        let mut last_word_byte_len = decoded_rlp_len % 8;
                        if last_word_byte_len == 0 {
                            last_word_byte_len = 8;
                        }
                        (l, last_word_byte_len)
                    },
                }
            },
        }
    }

    pub fn decode_block_number(rlp_list: (Words64, usize)) -> u256 {
        let (block_number_words, block_number_words_len) = rlp_list;
        assert(block_number_words.len() == 1, 'ERR_DECODE_PARENT_HASH_LIST_LEN');

        let block_number_le = *block_number_words.at(0);

        reverse_endianness_u64(block_number_le, Option::Some(block_number_words_len)).into()
    }

    pub fn decode_parent_hash(rlp_list: (Words64, usize)) -> u256 {
        let (words, words_byte_len) = rlp_list;
        assert(words.len() == 4 && words_byte_len == 32, 'INVALID_PARENT_HASH_RLP');
        words.as_u256_le().unwrap()
    }
}
