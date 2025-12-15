#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <map>
#include <algorithm>
#include <iomanip>
#include <cstdint> // Indispensable pour uint8_t, uint16_t
#include <bitset>  // Pour l'affichage binaire dans le MIF

// --- CONFIGURATION ---
const int BOOTLOADER_ROM_SIZE = 65536; // Taille de la ROM physique (pour le .mif)

const std::map<std::string, uint8_t> OPCODES = {
    // Instructions de base
    {"LDA", 0},  {"ADD", 1},  {"OUT", 2},  {"JZ", 3},
    {"SUB", 4},  {"STA", 5},  {"LDR", 6},  {"JMP", 7},
    {"IN", 8},   {"JE", 9},
    
    // Extensions 16-bits & Bootloader
    {"LHI", 10}, {"STI", 11}, {"RUN", 12},

    // ALU 2.0
    {"AND", 13}, {"OR", 14},  {"XOR", 15},

    // Stack & Fonctions
    {"PUSH", 16},{"POP", 17}, {"CALL", 18},{"RET", 19}
};

// --- UTILITAIRES ---
std::string toUpper(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), ::toupper);
    return s;
}

bool parseNumber(const std::string& s, int& result) {
    try {
        result = std::stoi(s, nullptr, 0); // Auto-détection (0x..., 10)
        return true;
    } catch (...) {
        return false;
    }
}

// --- CLASSE ASSEMBLER ---
class Assembler {
private:
    std::vector<std::string> source_lines;
    std::map<std::string, int> symbol_table;
    std::vector<uint16_t> binary_code;

    std::string cleanLine(const std::string& line) {
        // Garde ce qui est avant le point-virgule
        std::string clean = line.substr(0, line.find(';'));
        return clean;
    }

public:
    // 1. Chargement
    bool loadFile(const std::string& filename) {
        std::ifstream file(filename);
        if (!file.is_open()) {
            std::cerr << "[ERREUR] Impossible d'ouvrir le fichier : " << filename << std::endl;
            return false;
        }
        std::string line;
        while (std::getline(file, line)) {
            source_lines.push_back(line);
        }
        file.close();
        return true;
    }

    // 2. Passe 1 : Repérage des Labels
    void pass1() {
        int pc = 0;
        std::cout << "--- PASSE 1 : Analyse des Symboles ---" << std::endl;
        symbol_table.clear();

        for (const auto& raw_line : source_lines) {
            std::string line = cleanLine(raw_line);
            std::stringstream ss(line);
            std::string word;
            
            if (!(ss >> word)) continue; 

            if (word.back() == ':') {
                std::string label = word.substr(0, word.size() - 1);
                label = toUpper(label);
                
                if (symbol_table.count(label)) {
                    std::cerr << "[ERREUR FATALE] Label duplique : " << label << std::endl;
                    exit(1);
                }
                symbol_table[label] = pc;
                // std::cout << "Label : " << label << " -> " << pc << std::endl;
            } else {
                pc++;
            }
        }
    }

    // 3. Passe 2 : Génération du Binaire interne
    void pass2() {
        std::cout << "--- PASSE 2 : Encodage ---" << std::endl;
        binary_code.clear();
        int line_num = 0;

        for (const auto& raw_line : source_lines) {
            line_num++;
            std::string line = cleanLine(raw_line);
            std::stringstream ss(line);
            std::string cmd, arg_str;

            if (!(ss >> cmd)) continue; 
            if (cmd.back() == ':') continue; // Label déjà traité

            cmd = toUpper(cmd);

            if (OPCODES.find(cmd) == OPCODES.end()) {
                std::cerr << "[ERREUR Ligne " << line_num << "] Instruction inconnue : " << cmd << std::endl;
                exit(1);
            }
            uint8_t opcode = OPCODES.at(cmd);
            uint8_t operand = 0;

            if (ss >> arg_str) {
                int val;
                std::string arg_upper = toUpper(arg_str);
                
                // Priorité aux Labels
                if (symbol_table.count(arg_upper)) {
                    int full_addr = symbol_table[arg_upper];
                    operand = full_addr & 0xFF; // On coupe à 8 bits
                    
                    if (full_addr > 255) {
                        std::cout << "[INFO Ligne " << line_num << "] Label lointain (Adr " << full_addr 
                                  << "). Assurez-vous d'avoir fait un LHI." << std::endl;
                    }
                } 
                // Sinon c'est un nombre
                else if (parseNumber(arg_str, val)) {
                    if (val > 255) std::cout << "[WARN Ligne " << line_num << "] Valeur > 255 tronquee." << std::endl;
                    operand = val & 0xFF;
                } 
                else {
                    std::cerr << "[ERREUR Ligne " << line_num << "] Argument invalide : " << arg_str << std::endl;
                    exit(1);
                }
            }

            uint16_t instruction = (opcode << 8) | operand;
            binary_code.push_back(instruction);
        }
        std::cout << "Assemblage termine : " << binary_code.size() << " instructions." << std::endl;
    }

    // --- SORTIE : BINAIRE (Pour l'upload via Python) ---
    void saveToBin(const std::string& output_filename) {
        std::ofstream out(output_filename, std::ios::binary);
        if (!out.is_open()) return;

        // Header Taille (1 octet)
        uint8_t size = (uint8_t)binary_code.size();
        out.write(reinterpret_cast<char*>(&size), 1);

        for (uint16_t word : binary_code) {
            uint8_t high = (word >> 8) & 0xFF;
            uint8_t low = word & 0xFF;
            out.write(reinterpret_cast<char*>(&high), 1);
            out.write(reinterpret_cast<char*>(&low), 1);
        }
        out.close();
        std::cout << "\n[SUCCES] Fichier BINAIRE genere : " << output_filename << std::endl;
        std::cout << "-> A envoyer avec le script Python via USB." << std::endl;
    }

    // --- SORTIE : MIF (Pour Quartus/Bootloader) ---
    void saveToMif(const std::string& output_filename) {
        std::ofstream out(output_filename);
        if (!out.is_open()) return;

        out << "-- Fichier generé automatiquement par l'Assembleur" << std::endl;
        out << "DEPTH = " << BOOTLOADER_ROM_SIZE << ";" << std::endl;
        out << "WIDTH = 16;" << std::endl;
        out << "ADDRESS_RADIX = DEC;" << std::endl;
        out << "DATA_RADIX = BIN;" << std::endl;
        out << "CONTENT" << std::endl;
        out << "BEGIN" << std::endl;

        for (size_t i = 0; i < binary_code.size(); i++) {
            // Format : "Addresse : 16_bits_binaires;"
            out << i << " : " << std::bitset<16>(binary_code[i]) << ";" << std::endl;
        }

        // Remplissage avec des zéros si le programme est plus petit que la ROM
        if (binary_code.size() < BOOTLOADER_ROM_SIZE) {
            out << "[" << binary_code.size() << ".." << (BOOTLOADER_ROM_SIZE - 1) << "] : 0000000000000000;" << std::endl;
        }

        out << "END;" << std::endl;
        out.close();
        std::cout << "\n[SUCCES] Fichier MIF genere : " << output_filename << std::endl;
        std::cout << "-> A utiliser dans Quartus pour la ROM (Bootloader)." << std::endl;
    }
};

// --- MAIN : GESTION DES ARGUMENTS ---
int main(int argc, char* argv[]) {
    // Vérification basique des arguments
    if (argc < 3) {
        std::cout << "Usage :" << std::endl;
        std::cout << "  " << argv[0] << " <source.asm> -bin   -> Genere programme.bin (Pour upload)" << std::endl;
        std::cout << "  " << argv[0] << " <source.asm> -mif   -> Genere programme.mif (Pour Quartus)" << std::endl;
        return 1;
    }

    std::string filename = argv[1];
    std::string mode = argv[2];

    Assembler asm_compiler;

    // 1. Lecture
    if (!asm_compiler.loadFile(filename)) return 1;

    // 2. Compilation (commune)
    asm_compiler.pass1();
    asm_compiler.pass2();

    // 3. Export selon le mode choisi
    if (mode == "-bin") {
        asm_compiler.saveToBin("programme.bin");
    } 
    else if (mode == "-mif") {
        asm_compiler.saveToMif("programme.mif");
    } 
    else {
        std::cerr << "[ERREUR] Mode inconnu : " << mode << std::endl;
        std::cout << "Utilisez -bin ou -mif" << std::endl;
        return 1;
    }

    return 0;
}