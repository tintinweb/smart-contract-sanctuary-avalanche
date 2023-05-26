/**
 *Submitted for verification at snowtrace.io on 2023-05-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Perpustakaan {
    struct Buku {
        uint256 id;
        string judul;
        string pengarang;
        bool dipinjam;
    }

    mapping(uint256 => Buku) private bukuMapping; // Membuat pemetaan untuk memetakan ID buku ke objek Buku
    uint256 private jumlahBuku; // Menyimpan jumlah total buku

    event BukuDitambahkan(uint256 indexed id, string judul, string pengarang); // Event yang akan dipancarkan ketika buku ditambahkan
    event BukuDipinjam(uint256 indexed id); // Event yang akan dipancarkan ketika buku dipinjam
    event BukuDikembalikan(uint256 indexed id); // Event yang akan dipancarkan ketika buku dikembalikan

    constructor() {
        jumlahBuku = 0;
    }

    function tambahBuku(string memory _judul, string memory _pengarang) public {
        jumlahBuku++; // Menambah jumlah total buku
        bukuMapping[jumlahBuku] = Buku(jumlahBuku, _judul, _pengarang, false); // Menyimpan buku baru dalam pemetaan buku dengan ID yang unik
        emit BukuDitambahkan(jumlahBuku, _judul, _pengarang); // Memancarkan event BukuDitambahkan dengan detail buku yang baru ditambahkan
    }

    function pinjamBuku(uint256 _id) public {
        require(bukuMapping[_id].id != 0, "Buku tidak ditemukan"); // Memastikan buku dengan ID yang diberikan ada dalam sistem
        require(!bukuMapping[_id].dipinjam, "Buku sudah dipinjam"); // Memastikan buku belum dipinjam sebelumnya

        bukuMapping[_id].dipinjam = true; // Menandai buku sebagai dipinjam
        emit BukuDipinjam(_id); // Memancarkan event BukuDipinjam dengan ID buku yang dipinjam
    }

    function kembalikanBuku(uint256 _id) public {
        require(bukuMapping[_id].id != 0, "Buku tidak ditemukan"); // Memastikan buku dengan ID yang diberikan ada dalam sistem
        require(bukuMapping[_id].dipinjam, "Buku belum dipinjam"); // Memastikan buku sudah dipinjam sebelumnya

        bukuMapping[_id].dipinjam = false; // Menandai buku sebagai dikembalikan
        emit BukuDikembalikan(_id); // Memancarkan event BukuDikembalikan dengan ID buku yang dikembalikan
    }

    function cekStatusBuku(uint256 _id) public view returns (bool) {
        require(bukuMapping[_id].id != 0, "Buku tidak ditemukan"); // Memastikan buku dengan ID yang diberikan ada dalam sistem
        return bukuMapping[_id].dipinjam; // Mengembalikan status peminjaman buku
    }
}