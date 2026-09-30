// Definición para el nodo de una lista enlazada simple.
class ListNode {
  int val;
  ListNode? next;
  ListNode([this.val = 0, this.next]);
}

class Solution {
  ListNode? mergeTwoLists(ListNode? list1, ListNode? list2) {
    // Creamos un nodo 'dummy' (ficticio) para facilitar el manejo del inicio de la nueva lista.
    ListNode dummy = ListNode(0);
    ListNode current = dummy;

    // Recorremos ambas listas mientras ninguna esté vacía
    while (list1 != null && list2 != null) {
      if (list1.val <= list2.val) {
        current.next = list1;
        list1 = list1.next;
      } else {
        current.next = list2;
        list2 = list2.next;
      }
      // Avanzamos el puntero de la lista combinada
      current = current.next!;
    }

    // Si alguna de las listas aún tiene elementos, los añadimos al final
    current.next = list1 ?? list2;

    // Retornamos el nodo inicial real (saltando el nodo 'dummy')
    return dummy.next;
  }
}

// Función auxiliar para imprimir la lista resultante fácilmente
void imprimirLista(ListNode? nodo, int numeroEjemplo) {
  List<int> salida = [];
  while (nodo != null) {
    salida.add(nodo.val);
    nodo = nodo.next;
  }
  print('Salida Ejemplo $numeroEjemplo: $salida');
}

void main() {
  Solution solucion = Solution();

  // --- Ejemplo 1 ---
  // Entrada: lista1 = [1,2,4], lista2 = [1,3,4]
  ListNode l1_ej1 = ListNode(1, ListNode(2, ListNode(4)));
  ListNode l2_ej1 = ListNode(1, ListNode(3, ListNode(4)));
  
  ListNode? resultado1 = solucion.mergeTwoLists(l1_ej1, l2_ej1);
  imprimirLista(resultado1, 1); 
  // Salida esperada: [1, 1, 2, 3, 4, 4]


  // --- Ejemplo 2 ---
  // Entrada: lista1 = [], lista2 = []
  ListNode? l1_ej2 = null;
  ListNode? l2_ej2 = null;
  
  ListNode? resultado2 = solucion.mergeTwoLists(l1_ej2, l2_ej2);
  imprimirLista(resultado2, 2); 
  // Salida esperada: []


  // --- Ejemplo 3 ---
  // Entrada: lista1 = [], lista2 = [0]
  ListNode? l1_ej3 = null;
  ListNode? l2_ej3 = ListNode(0);
  
  ListNode? resultado3 = solucion.mergeTwoLists(l1_ej3, l2_ej3);
  imprimirLista(resultado3, 3); 
  // Salida esperada: [0]
}