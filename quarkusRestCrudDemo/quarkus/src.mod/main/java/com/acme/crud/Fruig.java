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
@Table(name = "known_fruigs")
@NamedQuery(name = "Fruigs.findAll",
      query = "SELECT f FROM Fruig f ORDER BY f.name")
public class Fruig {

    @Id
    @SequenceGenerator(
            name = "fruigsSequence",
            sequenceName = "known_fruigs_id_seq",
            allocationSize = 1,
            initialValue = 4)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "fruigsSequence")
    private Integer id;

    @Column(length = 40, unique = true)
    private String name;

    public Fruig() {
    }

    public Fruig(String name) {
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
