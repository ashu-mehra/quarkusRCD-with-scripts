package com.acme.crud;

import javax.persistence.Cacheable;
import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.NamedQuery;
import javax.persistence.QueryHint;
import javax.persistence.SequenceGenerator;
import javax.persistence.Table;

@Entity
@Table(name = "known_fruifs")
@NamedQuery(name = "Fruifs.findAll",
      query = "SELECT f FROM Fruif f ORDER BY f.name")
public class Fruif {

    @Id
    @SequenceGenerator(
            name = "fruifsSequence",
            sequenceName = "known_fruifs_id_seq",
            allocationSize = 1,
            initialValue = 4)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "fruifsSequence")
    private Integer id;

    @Column(length = 40, unique = true)
    private String name;

    public Fruif() {
    }

    public Fruif(String name) {
        this.name = name;
    }

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }
}
