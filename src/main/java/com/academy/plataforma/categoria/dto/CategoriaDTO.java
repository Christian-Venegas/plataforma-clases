package com.academy.plataforma.categoria.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CategoriaDTO {

    private Long idCategorias;

    @NotBlank(message = "El nombre es obligatorio")  // validacion: no vacio
    @Size(max = 100, message = "Maximo 100 caracteres")
    private String nombre;

    @Size(max = 300, message = "Maximo 300 caracteres")
    private String descripcion;

    @Size(max = 100)
    private String icono;
}
