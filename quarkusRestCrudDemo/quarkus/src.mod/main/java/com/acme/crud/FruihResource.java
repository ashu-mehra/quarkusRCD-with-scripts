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

@Path("fruihs")
@ApplicationScoped
@Produces("application/json")
@Consumes("application/json")
public class FruihResource {

    @Inject
    EntityManager entityManager;

    @GET
    public Fruih[] get() {
//        System.out.println(new SimpleDateFormat("HH:mm:ss.SSS").format(new Date()));
        return entityManager.createNamedQuery("Fruihs.findAll", Fruih.class)
              .getResultList().toArray(new Fruih[0]);
    }

    @GET
    @Path("{id}")
    public Fruih getSingle(@PathParam Integer id) {
        Fruih entity = entityManager.find(Fruih.class, id);
        if (entity == null) {
            throw new WebApplicationException("Fruih with id of " + id + " does not exist.", 404);
        }
        return entity;
    }

    @POST
    @Transactional
    public Response create(Fruih fruih) {
        if (fruih.getId() != null) {
            throw new WebApplicationException("Id was invalidly set on request.", 422);
        }

        entityManager.persist(fruih);
        return Response.ok(fruih).status(201).build();
    }

    @PUT
    @Path("{id}")
    @Transactional
    public Fruih update(@PathParam Integer id, Fruih fruih) {
        if (fruih.getName() == null) {
            throw new WebApplicationException("Fruih Name was not set on request.", 422);
        }

        Fruih entity = entityManager.find(Fruih.class, id);

        if (entity == null) {
            throw new WebApplicationException("Fruih with id of " + id + " does not exist.", 404);
        }

        entity.setName(fruih.getName());

        return entity;
    }

    @DELETE
    @Path("{id}")
    @Transactional
    public Response delete(@PathParam Integer id) {
        Fruih entity = entityManager.getReference(Fruih.class, id);
        if (entity == null) {
            throw new WebApplicationException("Fruih with id of " + id + " does not exist.", 404);
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
