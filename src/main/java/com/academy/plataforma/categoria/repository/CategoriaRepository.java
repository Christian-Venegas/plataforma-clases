package com.academy.plataforma.categoria.repository;

import com.academy.plataforma.categoria.entity.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CategoriaRepository extends JpaRepository<Categoria, Long> {

    // Spring genera la consulta Solo con el nombre del metodo
    Optional<Categoria> findByNombre(String nombre);

    boolean existsByNombre(String nombre);

}
