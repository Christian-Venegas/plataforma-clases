package com.academy.plataforma.categoria.controller;

import com.academy.plataforma.categoria.dto.CategoriaDTO;
import com.academy.plataforma.categoria.service.CategoriaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController                              // 1. Controller que devuelve JSON
@RequestMapping("/api/categorias")           // 2. Todas las rutas empiezan así
@RequiredArgsConstructor
public class CategoriaController {

    private final CategoriaService categoriaService;

    // ===== GET /api/categorias  → listar =====
    @GetMapping
    public ResponseEntity<List<CategoriaDTO>> listar() {
        return ResponseEntity.ok(categoriaService.listar());
    }

    // ===== POST /api/categorias  → crear =====
    @PostMapping
    public ResponseEntity<CategoriaDTO> crear(@Valid @RequestBody CategoriaDTO dto) {
        CategoriaDTO creada = categoriaService.crear(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(creada);
    }
}