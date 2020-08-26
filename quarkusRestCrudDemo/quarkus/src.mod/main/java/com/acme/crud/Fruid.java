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
@Table(name = "known_fruids")
@NamedQuery(name = "Fruids.findAll",
      query = "SELECT f FROM Fruid f ORDER BY f.name")
public class Fruid {

    @Id
    @SequenceGenerator(
            name = "fruidsSequence",
            sequenceName = "known_fruids_id_seq",
            allocationSize = 1,
            initialValue = 4)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "fruidsSequence")
    private Integer id;

    @Column(length = 40, unique = true)
    private String name;

    public Fruid() {
    }

    public Fruid(String name) {
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
