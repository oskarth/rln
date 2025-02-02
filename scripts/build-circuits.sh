cd "$(dirname "$0")"

mkdir -p ../build
mkdir -p ../zkeyFiles
mkdir -p ../contracts

cd ../build

if [ -f ./powersOfTau28_hez_final_14.ptau ]; then
    echo "powersOfTau28_hez_final_14.ptau already exists. Skipping."
else
    echo 'Downloading powersOfTau28_hez_final_14.ptau'
    wget https://hermez.s3-eu-west-1.amazonaws.com/powersOfTau28_hez_final_14.ptau
fi

circuit_path=""
if [ "$1" = "rln" ]; then 
    circuit_path="../circuits/rln.circom"
elif [ "$1" = "nrln" ]; then
    circuit_path="../circuits/nrln.circom"
fi

echo "Circuit path: $circuit_path"

circom $circuit_path --r1cs --wasm --sym
snarkjs r1cs export json rln.r1cs rln.r1cs.json

snarkjs groth16 setup rln.r1cs powersOfTau28_hez_final_14.ptau rln_0000.zkey

snarkjs zkey contribute rln_0000.zkey rln_0001.zkey --name="Frist contribution" -v -e="Random entropy"
snarkjs zkey contribute rln_0001.zkey rln_0002.zkey --name="Second contribution" -v -e="Another random entropy"
snarkjs zkey beacon rln_0002.zkey rln_final.zkey 0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f 10 -n="Final Beacon phase2"

snarkjs zkey export verificationkey rln_final.zkey verification_key.json
snarkjs zkey export solidityverifier rln_final.zkey verifier.sol

cp verifier.sol ../contracts/Verifier.sol
cp verification_key.json ../zkeyFiles/verification_key.json
cp rln_js/rln.wasm ../zkeyFiles/rln.wasm
cp rln_final.zkey ../zkeyFiles/rln_final.zkey