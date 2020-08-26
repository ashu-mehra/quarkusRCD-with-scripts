package com.acme.crud;

import java.text.SimpleDateFormat;
import java.util.Date;

import javax.enterprise.context.ApplicationScoped;
import javax.enterprise.event.Observes;
import javax.inject.Inject;
import javax.json.Json;
import javax.persistence.EntityManager;
import javax.transaction.Transactional;
import javax.ws.rs.Consumes;
import javax.ws.rs.DELETE;
import javax.ws.rs.GET;
import javax.ws.rs.POST;
import javax.ws.rs.PUT;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.WebApplicationException;
import javax.ws.rs.core.Response;
import javax.ws.rs.ext.ExceptionMapper;
import javax.ws.rs.ext.Provider;

import org.jboss.resteasy.annotations.jaxrs.PathParam;

import io.quarkus.runtime.StartupEvent;

@Path("fruijs")
@ApplicationScoped
@Produces("application/json")
@Consumes("application/json")
public class FruijResource {

    @Inject
    EntityManager entityManager;

    @GET
    public Fruij[] get() {
//        System.out.println(new SimpleDateFormat("HH:mm:ss.SSS").format(new Date()));
        return entityManager.createNamedQuery("Fruijs.findAll", Fruij.class)
              .getResultList().toArray(new Fruij[0]);
    }

    @GET
    @Path("{id}")
    public Fruij getSingle(@PathParam Integer id) {
        Fruij entity = entityManager.find(Fruij.class, id);
        if (entity == null) {
            throw new WebApplicationException("Fruij with id of " + id + " does not exist.", 404);
        }
        return entity;
    }

    @POST
    @Transactional
    public Response create(Fruij fruij) {
        if (fruij.getId() != null) {
            throw new WebApplicationException("Id was invalidly set on request.", 422);
        }

        entityManager.persist(fruij);
        return Response.ok(fruij).status(201).build();
    }

    @PUT
    @Path("{id}")
    @Transactional
    public Fruij update(@PathParam Integer id, Fruij fruij) {
        if (fruij.getName() == null) {
            throw new WebApplicationException("Fruij Name was not set on request.", 422);
        }

        Fruij entity = entityManager.find(Fruij.class, id);

        if (entity == null) {
            throw new WebApplicationException("Fruij with id of " + id + " does not exist.", 404);
        }

        entity.setName(fruij.getName());

        return entity;
    }

    @DELETE
    @Path("{id}")
    @Transactional
    public Response delete(@PathParam Integer id) {
        Fruij entity = entityManager.getReference(Fruij.class, id);
        if (entity == null) {
            throw new WebApplicationException("Fruij with id of " + id + " does not exist.", 404);
        }
        entityManager.remove(entity);
        return Response.status(204).build();
    }
    
    void onStart(@Observes StartupEvent startup) {
        System.out.println(new SimpleDateFormat("HH:mm:ss.SSS").format(new Date()));
    }

    @Provider
    public static class ErrorMapper implements ExceptionMapper<Exception> {

        @Override
        public Response toResponse(Exception exception) {
            int code = 500;
            if (exception instanceof WebApplicationException) {
                code = ((WebApplicationException) exception).getResponse().getStatus();
            }
            return Response.status(code)
                    .entity(Json.createObjectBuilder().add("error", exception.getMessage()).add("code", code).build())
                    .build();
        }

    }
}
