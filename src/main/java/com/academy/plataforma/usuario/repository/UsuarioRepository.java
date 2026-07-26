package com.academy.plataforma.usuario.repository;

import com.academy.plataforma.usuario.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    // Spring genera el Sql solo: Busca un usuario por su email
    Optional<Usuario> findByEmail(String email);

    // Verifica si ya existe un email (para el registro)
    boolean existsByEmail(String email);

}
