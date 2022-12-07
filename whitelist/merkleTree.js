const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

let whitelistedAddress = [
    '0x5B38Da6a701c568545dCfcB03FcB875f56beddC4',
    '0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2',
    '0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db',
    '0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB',
    '0x70997970C51812dc3A010C7d01b50e0d17dc79C8',
    '0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC',
    '0x53874cd62cc7a574f7cbc1088f8560739fafeb27'
]

const leafNode = whitelistedAddress.map((addr) => keccak256(addr))
const merkleTree = new MerkleTree(leafNode, keccak256, { sortPairs: true })
const buf2Hex = (x) => '0x' + x.toString('hex')
const rootHash = merkleTree.getRoot()
const mintingAddress = leafNode[0]
const hexProof = merkleTree.getHexProof(mintingAddress)
console.log({
    rootHash: buf2Hex(rootHash),
    hexProof: hexProof.toString(),
    addr: buf2Hex(mintingAddress),
})
