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
@Table(name = "known_fruics")
@NamedQuery(name = "Fruics.findAll",
      query = "SELECT f FROM Fruic f ORDER BY f.name")
public class Fruic {

    @Id
    @SequenceGenerator(
            name = "fruicsSequence",
            sequenceName = "known_fruics_id_seq",
            allocationSize = 1,
            initialValue = 4)
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "fruicsSequence")
    private Integer id;

    @Column(length = 40, unique = true)
    private String name;

    public Fruic() {
    }

    public Fruic(String name) {
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
