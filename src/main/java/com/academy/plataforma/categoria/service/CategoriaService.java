package com.academy.plataforma.categoria.service;

import com.academy.plataforma.categoria.dto.CategoriaDTO;
import com.academy.plataforma.categoria.entity.Categoria;
import com.academy.plataforma.categoria.repository.CategoriaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service                              // 1. Marca esta clase como capa de negocio
@RequiredArgsConstructor              // 2. Lombok: inyecta el repository automáticamente
public class CategoriaService {

    private final CategoriaRepository categoriaRepository;   // 3. inyección de dependencia

    // ===== LISTAR todas =====
    @Transactional(readOnly = true)
    public List<CategoriaDTO> listar() {
        return categoriaRepository.findAll()
                .stream()
                .map(this::aDTO)      // convierte cada entidad a DTO
                .toList();
    }

    // ===== CREAR una =====
    @Transactional
    public CategoriaDTO crear(CategoriaDTO dto) {
        // Regla de negocio: no permitir nombres duplicados
        if (categoriaRepository.existsByNombre(dto.getNombre())) {
            throw new IllegalArgumentException("Ya existe una categoría con ese nombre");
        }
        Categoria categoria = Categoria.builder()
                .nombre(dto.getNombre())
                .descripcion(dto.getDescripcion())
                .icono(dto.getIcono())
                .build();
        Categoria guardada = categoriaRepository.save(categoria);
        return aDTO(guardada);
    }

    // ===== Conversor: Entidad -> DTO =====
    private CategoriaDTO aDTO(Categoria c) {
        return CategoriaDTO.builder()
                .idCategorias(c.getIdCategorias())
                .nombre(c.getNombre())
                .descripcion(c.getDescripcion())
                .icono(c.getIcono())
                .build();
    }
}