#include <NTL/ZZ.h>
#include <NTL/ZZ_p.h>
#include <NTL/ZZ_pX.h>
#include <NTL/ZZ_pXFactoring.h>
#include <iostream>
#include <sstream>

using namespace std;
using namespace NTL;

using namespace std;
using namespace NTL;

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

    // Vyber rezimu
    int rezim;
    cout << "-------------------------------------------------------------------------------------------------------------------"<< endl;
    cout << "Vypocet periody z charakteristickeho polynomu zadajte => 1" << endl;
    cout << "Vypocet periody z postupnosti dlzky n zadajte => 2"<< endl;
    cout << "-------------------------------------------------------------------------------------------------------------------"<< endl;
    cout << "Zadajte moznost: " ;

    while (!(cin >> rezim) || (rezim != 1 && rezim != 2)) {
        cin.clear(); // Clear error flags
        cin.ignore(numeric_limits<streamsize>::max(), '\n'); // Discard invalid input
        cout << "Zadajte len hodnotu 1 alebo 2: ";
    }



    // Zadanie mod p
    ZZ p;
    cout << "Zadajte prvocislo ako modulo p: ";
    cin >> p;
    cin.ignore();
    while (!ProbPrime(p)) {
        cout << "Zadana hodnota nie je prvocislo. Zadajte prvocislo: ";
        cin >> p;
        cin.ignore();
    }
    ZZ_p::init(p);

    // Ratanie periody z charakteristickeho polynomu


    if (rezim == 1) {
        // Zadanie charakteristickeho polynomu
        string charPolyInput;
        bool validFormat = false;
        while (!validFormat) {
            cout << "--------------------------------------------------------------------"<< endl;
            cout << "Charakteristicky polynom sa zadava vo formate [x^0 x^1 x^2 x^3 ... ]" << endl;
            cout << "Priklad zadania [1 0 1 1] je 1+x^2+x^3 " << endl;
            cout << "--------------------------------------------------------------------"<< endl;
            cout << "Zadajte charakteristicky polynom: ";
            getline(cin, charPolyInput);

            // Ensure the input is enclosed within brackets
            if (charPolyInput.front() == '[' && charPolyInput.back() == ']') {
                // Extracting numbers from the input string
                string numbers;
                for (char ch : charPolyInput) {
                    if (isdigit(ch)) {
                        numbers += ch;
                    }
                }

                // Check if at least one number was found
                if (!numbers.empty()) {
                    validFormat = true;

                    // Convert the extracted numbers to ZZ_pX polynomial
                    ZZ_pX charPoly;
                    for (char ch : numbers) {
                        SetCoeff(charPoly, charPoly.rep.length(), ch - '0');
                    }

                    // Faktorizacia polynomu
                    vec_pair_ZZ_pX_long factors;
                    CanZass(factors, charPoly);
                    int* exponenty = new int[factors.length()];
                    int* periody = new int[factors.length()];

                    // Vypis faktorov
                    cout << "Faktorizacia charakteristickeho polynomu: " << endl;
                    for (long i = 0; i < factors.length(); i++) {
                        cout << "Faktor " << i + 1 << ": " << factors[i].a << " s mocninou " << factors[i].b << endl;

                        // do string
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
                    //cout << "Maximalny exponent je: " << maximum << endl;

                    long nsd_ord = nsnPole(periody, factors.length());
                    //cout << "NSN radov: " << nsd_ord << endl;

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
                    //cout << "Mocnina: " << mocnina << endl;

                    cout << "Perioda: " << mocnina*nsd_ord << endl;
                }
            }

            if (!validFormat) {
                cout << "Chybny format. Polynom musi byt uzatvoreny v zatvorkach [ ]." << endl;
            }
        }
    }


    // Ratanie periody zo zadanej postupnosti
    if (rezim == 2) {
        // Zadanie postupnosti
        string sequence;
        cout << "Zadajte postupnost: ";
        getline(cin, sequence);

        // Remove spaces from the sequence
        string sanitizedSequence;
        for (char ch : sequence) {
            if (!isspace(ch)) {
                sanitizedSequence += ch;
            }
        }

        // Validate input sequence (len cisla)
        bool validInput = true;
        for (char ch : sanitizedSequence) {
            if (!isdigit(ch)) {
                validInput = false;
                break;
            }
        }

        if (!validInput) {
            cout << "Chybna postupnost. Zadajte len ciselne hodnoty." << endl;
            return 1;
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
        cout << "Minimalny polynom postupnosti: " << minPoly << endl;
        if (IterIrredTest(minPoly)) {
            cout << "je ireducibilny" << endl;
        }

        /* // Najdenie periody
         long n = 1;
         do {
             // Polynom (x^n - 1)
             ZZ_pX x_n;
             SetCoeff(x_n, n, 1);
             x_n = x_n - 1;
             // Test, ci minimalny polynom deli (x^n - 1)
             if (divide(x_n, minPoly)) {
                 break;
             }
             // Ak nie, skusit s n++
             n++;
         } while (true);
         */
        cout << "Perioda: " << mulOrd(minPoly) << endl;
    }

    return 0;
}
