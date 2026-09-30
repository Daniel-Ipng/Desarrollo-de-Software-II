class Solution {
  int contarFrutasSinColocar(List<int> frutas, List<int> cestas) {
    int frutasSinColocar = 0;
    // Usamos un conjunto (Set) para registrar los índices de las cestas que ya han sido ocupadas.
    Set<int> cestasOcupadas = {};

    // Iteramos sobre cada tipo de fruta
    for (int i = 0; i < frutas.length; i++) {
      int cantidadFruta = frutas[i];
      bool colocada = false;

      // Buscamos la cesta más a la izquierda disponible
      for (int j = 0; j < cestas.length; j++) {
        // Verificamos si la cesta NO está en el conjunto de ocupadas y si tiene capacidad suficiente
        if (!cestasOcupadas.contains(j) && cestas[j] >= cantidadFruta) {
          cestasOcupadas.add(j); // Marcamos la cesta como ocupada
          colocada = true;
          break; // Pasamos al siguiente tipo de fruta
        }
      }

      // Si después de revisar todas las cestas no se pudo colocar, incrementamos el contador
      if (!colocada) {
        frutasSinColocar++;
      }
    }

    return frutasSinColocar;
  }
}

void main() {
  Solution solucion = Solution();

  // --- Ejemplo 1 ---
  // Entrada: frutas = [4,2,5], cestas = [3,5,4]
  List<int> frutasEj1 = [4, 2, 5];
  List<int> cestasEj1 = [3, 5, 4];
  int resultado1 = solucion.contarFrutasSinColocar(frutasEj1, cestasEj1);
  print('Salida Ejemplo 1: $resultado1'); 
  // Salida esperada: 1

  // --- Ejemplo 2 ---
  // Entrada: frutas = [3,6,1], cestas = [6,4,7]
  List<int> frutasEj2 = [3, 6, 1];
  List<int> cestasEj2 = [6, 4, 7];
  int resultado2 = solucion.contarFrutasSinColocar(frutasEj2, cestasEj2);
  print('Salida Ejemplo 2: $resultado2'); 
  // Salida esperada: 0
}