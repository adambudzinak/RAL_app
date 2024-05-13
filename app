#include <NTL/ZZ.h>
#include <NTL/ZZ_p.h>
#include <NTL/ZZ_pX.h>
#include <NTL/ZZ_pXFactoring.h>
#include <iostream>
#include <sstream>
#include <vector>

using namespace std;
using namespace NTL;

// premena seqvencie na string
void string_to_polynomial(const string& s) {
    vector<int> coef;
    istringstream iss(s.substr(1, s.size() - 2)); // remove brackets
    string coeff_str;
    while (iss >> coeff_str) {
        coef.push_back(stoi(coeff_str));
    }
    string result;
    for (int i = 0; i < coef.size(); ++i) {
        if (coef[i] != 0) {
            if (!result.empty()) {
                result += " + ";
            }
            if (coef[i] != 1 || i == 0) {
                result += to_string(coef[i]);
            }
            if (i > 0) {
                result += "x";
                if (i > 1) {
                    result += "^" + to_string(i);
                }
            }
        }
    }
    cout << "Polynom: " << result << endl;
}

// Najde rad (multiplicative order) polynomu
long mulOrd(const ZZ_pX& poly) {
    long n = 1;
    do {
        // Polynom (x^n - 1)
        ZZ_pX x_n;
        SetCoeff(x_n, n, 1);
        x_n = x_n - 1;
        // Test, ci minimalny polynom deli (x^n - 1)
        if (divide(x_n, poly)) {
            break;
        }
        // Ak nie, skusit s n++
        n++;
    } while (true);
    return n;
}

// Najvacsi spolocny delitel
int nsd(int a, int b) {
    while (b != 0) {
        int temp = b;
        b = a % b;
        a = temp;
    }
    return a;
}

// Najmensi spolocny nasobok
int nsn(int a, int b) {
    return (a * b) / nsd(a, b);
}

// NSN prvkov pola
int nsnPole(int pole[], int velkost) {
    int result = pole[0];
    for (int i = 1; i < velkost; ++i) {
        result = nsn(result, pole[i]);
    }
    return result;
}

int main() {
    string koniec = "0";
    while (koniec == "0") {
        // Vyber rezimu
        int rezim;
        cout << "--------------------------------------------------------------------" << endl;
        cout << "     Vypocet periody z charakteristickeho polynomu zadajte => 1     " << endl;
        cout << "         Vypocet periody z postupnosti dlzky n zadajte => 2         " << endl;
        cout << "--------------------------------------------------------------------" << endl;
        cout << "Zadajte moznost: ";

        while (!(cin >> rezim) || (rezim != 1 && rezim != 2)) {
            cin.clear(); // vymaz error ked uzivatel zada nieco ine ako cislo
            cin.ignore(numeric_limits<streamsize>::max(), '\n'); // ignoruj zly vstup
            cout << "Zadajte len hodnotu 1 alebo 2: ";
        }

        // Zadanie mod p
        ZZ p;
        cout << "Zadajte prvocislo ako modulo p: ";

        while (!(cin >> p) || !ProbPrime(p)) {
            cout << "Zadana hodnota nie je prvocislo. Zadajte prvocislo: ";
            cin.clear();
            cin.ignore(numeric_limits<streamsize>::max(), '\n');
        }
        ZZ_p::init(p);



        // Ratanie periody z charakteristickeho polynomu
        if (rezim == 1) {
            cin.ignore(numeric_limits<streamsize>::max(), '\n');

            cout << "--------------------------------------------------------------------" << endl;
            cout << "Charakteristicky polynom sa zadava vo formate [x^0 x^1 x^2 x^3 ... ]" << endl;
            cout << "Priklad zadania [1 0 1 1] je 1+x^2+x^3 " << endl;
            cout << "--------------------------------------------------------------------" << endl;
            cout << "Zadajte charakteristicky polynom mod(" << p << "): ";
            ZZ_pX charPoly;
            cin >> charPoly;

            // Faktorizacia polynomu
            vec_pair_ZZ_pX_long factors;
            CanZass(factors, charPoly);
            int* exponenty = new int[factors.length()];
            int* periody = new int[factors.length()];

            // Vypis faktorov
            cout << "Faktorizacia charakteristickeho polynomu: " << endl;
            for (long i = 0; i < factors.length(); i++) {
                cout << "Faktor " << i + 1 << ": " << factors[i].a << " s mocninou " << factors[i].b << endl;
                cout << "Polynom: ";
                // vypis polynomu v tvare x^0+x^1+...
                stringstream polynomialStr;
                for (long j = 0; j < factors[i].a.rep.length(); j++) {
                    if (coeff(factors[i].a, j) != 0) {
                        if (!polynomialStr.str().empty()) {
                            polynomialStr << " + ";
                        }
                        polynomialStr << coeff(factors[i].a, j);
                        if (j > 0) {
                            polynomialStr << "x";
                        }
                        if (j > 1) {
                            polynomialStr << "^" << j;
                        }
                    }
                }
                exponenty[i] = factors[i].b;
                periody[i] = mulOrd(factors[i].a);
                cout << polynomialStr.str() << endl;
            }

            // Hladanie maximalneho exponentu
            long maximum = exponenty[0];
            for (int i = 1; i < factors.length(); ++i) {
                if (exponenty[i] > maximum) {
                    maximum = exponenty[i];
                }
            }
            // Namensi spolocny nasobok radov faktorov
            long nsn_ord = nsnPole(periody, factors.length());

            // Uvolnenie pamate
            delete[] exponenty;
            delete[] periody;

            // Ak ma niektory faktor exponent vacsi ako 1
            long mocnina = to_long(p);
            if (maximum > 1) {
                long exponent = 1;
                while (mocnina < maximum) {
                    exponent++;
                    mocnina = pow(mocnina, exponent);
                }
            }
            else {
                mocnina = 1;
            }

            cout << "Perioda: " << mocnina * nsn_ord << endl;
        }


        // Ratanie periody zo zadanej postupnosti
        if (rezim == 2) {
            // Zadanie postupnosti
            string sequence;
            string sanitizedSequence;
            bool validInput = false;
            while (!validInput) {
                cout << "Zadajte periodicku postupnost bez predperiody: ";
                cin.ignore(numeric_limits<streamsize>::max(), '\n');
                getline(cin, sequence);
                validInput = true;

                sanitizedSequence = "";
                // over ci su tam iba ciselne hodnoty a odstran medzery vo vstupe
                for (char ch : sequence) {
                    if (!isdigit(ch)) {
                        validInput = false;
                        break;
                    }
                    if (!isspace(ch)) {
                        sanitizedSequence += ch;
                    }
                }


                if (!validInput) {
                    cout << "Chybna postupnost. Zadajte len ciselne hodnoty." << endl;
                }
            }
            int length = sanitizedSequence.size();
            vec_ZZ_p postupnost;
            postupnost.SetLength(length);
            for (int i = 0; i < length; ++i) {
                long num = sanitizedSequence[i] - '0';
                postupnost[i] = to_ZZ_p(num);
            }

            // Najdenie minimalneho polynomu
            ZZ_pX minPoly;
            MinPolySeq(minPoly, postupnost, (long)length / 2);

            // Vypis minimalneho polynomu
            cout << "\nVysledok: \n";
            cout << "Minimalny polynom postupnosti: " << minPoly << endl;

            stringstream ss;
            ss << minPoly;

            string polyStr = ss.str();
            string_to_polynomial(polyStr);

            if (coeff(minPoly, 0) == 0) {
                cout << "Postupnost ma predperiodu, zadajte prosim postupnost bez predperiody!" << endl;
            }
            else {
                if (mulOrd(minPoly) > length) {
                    cout << "Postupnost nie je periodicka" << endl;
                }
                else {
                    cout << "Perioda: " << mulOrd(minPoly) << endl;
                }
            }
        }
        cout << "\n";
        cout << "--------------------------------------------------------------------" << endl;
        cout << "Ak chcete pokracovat v zadavani, zadajte => 0" << endl;
        cout << "Ak chcete skoncit, zadajte lubovolny znak" << endl;
        cout << "--------------------------------------------------------------------" << endl;
        cout << "Zadajte moznost: ";
        cin >> koniec;
        cin.ignore(numeric_limits<streamsize>::max(), '\n');
    }

    return 0;
}
