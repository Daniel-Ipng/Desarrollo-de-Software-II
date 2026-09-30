class Solution {
  List<int> intersect(List<int> nums1, List<int> nums2) {
    Map<int, int> conteo = {};
    List<int> interseccion = [];

    // Contamos las frecuencias de cada número en el primer arreglo
    for (int num in nums1) {
      conteo[num] = (conteo[num] ?? 0) + 1;
    }

    // Comparamos con el segundo arreglo para encontrar las intersecciones
    for (int num in nums2) {
      if (conteo.containsKey(num) && conteo[num]! > 0) {
        interseccion.add(num);
        conteo[num] = conteo[num]! - 1; // Reducimos la frecuencia disponible
      }
    }

    return interseccion;
  }
}

void main() {
  Solution solucion = Solution();

  // --- Ejemplo 1 ---
  // Entrada: nums1 = [1,2,2,1], nums2 = [2,2]
  List<int> nums1_ej1 = [1, 2, 2, 1];
  List<int> nums2_ej1 = [2, 2];
  
  List<int> resultado1 = solucion.intersect(nums1_ej1, nums2_ej1);
  print('Salida Ejemplo 1: $resultado1'); 
  // Salida esperada: [2, 2]

  // --- Ejemplo 2 ---
  // Entrada: nums1 = [4,9,5], nums2 = [9,4,9,8,4]
  List<int> nums1_ej2 = [4, 9, 5];
  List<int> nums2_ej2 = [9, 4, 9, 8, 4];
  
  List<int> resultado2 = solucion.intersect(nums1_ej2, nums2_ej2);
  print('Salida Ejemplo 2: $resultado2'); 
  // Salida esperada: [9, 4] o [4, 9]
}