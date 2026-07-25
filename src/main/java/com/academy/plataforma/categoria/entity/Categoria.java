package com.academy.plataforma.categoria.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import java.time.LocalDateTime;

@Entity                          // 1. Le dice a JPA: "esta clase es una tabla"
@Table(name = "categorias")      // 2. Se conecta con la tabla 'categorias'
@Getter                          // 3. Lombok: crea los getters automáticamente
@Setter                          // 4. Lombok: crea los setters automáticamente
@NoArgsConstructor               // 5. Constructor vacío (JPA lo necesita)
@AllArgsConstructor              // 6. Constructor con todos los campos
@Builder                         // 7. Permite crear objetos de forma elegante
public class Categoria {

    @Id                                              // 8. Esta es la llave primaria (PK)
    @GeneratedValue(strategy = GenerationType.IDENTITY)  // 9. La BD genera el número solo
    @Column(name = "id_categorias")                  // 10. Se mapea a la columna id_categorias
    private Long idCategorias;

    @Column(name = "nombre", nullable = false, unique = true, length = 100)  // 11.
    private String nombre;

    @Column(name = "descripcion", length = 300)      // 12. Opcional (puede ser null)
    private String descripcion;

    @Column(name = "icono", length = 100)            // 13. Opcional
    private String icono;

    @CreationTimestamp                               // 14. Se llena solo al crear el registro
    @Column(name = "creado_en", updatable = false)   // 15. No se modifica después
    private LocalDateTime creadoEn;
}