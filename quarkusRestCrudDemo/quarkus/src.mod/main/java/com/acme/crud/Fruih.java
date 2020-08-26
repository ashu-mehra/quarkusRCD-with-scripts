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
@Table(name = "known_fruihs")
@NamedQuery(name = "Fruihs.findAll",
      query = "SELECT f FROM Fruih f ORDER BY f.name")
public class Fruih {

    @Id
    @SequenceGenerator(
            name = "fruihsSequence",
            sequenceName = "known_fruihs_id_seq",
            allocationSize = 1,
            initialValue = 4)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "fruihsSequence")
    private Integer id;

    @Column(length = 40, unique = true)
    private String name;

    public Fruih() {
    }

    public Fruih(String name) {
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
