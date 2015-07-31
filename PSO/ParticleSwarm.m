function [ bestSolution bestFitness fitnesses solutions ] = ParticleSwarm( numParticles, numDays, numTimeSlots, courses, rooms, students, iterations, noChangeProb, randomProb, pbestProb, gbestProb, Khard, Ksoft, handle )
% ParticleSwarm Algorithm to find best schedule
%
% numParticles Number
%      numDays Number
% numTimeSlots Number
%      courses List(Course)
%        rooms List(Classroom)
%     students List(Student)
%   iterations Number
% noChangeProb Number
%   randomProb Number
%    pbestProb Number
%    gbestProb Number
%        Khard Number
%        Ksoft Number
%       handle Object Handles
%
% Returns the best fitness and solutions for the inputs

particles = Particle.empty(numParticles, 0);
    
globalBestSol = 0;
globalBestFitness = Inf;

%initialize particles
for i = 1:numParticles
    particle = GenerateInitialSolution(numDays, numTimeSlots, courses, rooms);
    fitness = GetFitness(particle, students, Khard, Ksoft, false);

    particles(i) =  Particle(particle, particle, fitness);

    if fitness < globalBestFitness
        globalBestSol = particles(i).schedule;
        globalBestFitness = fitness;
    end
end



for i = 1:iterations
    bestPartSol = 0;
    bestPartFitness = Inf;
    for j = 1:numParticles
        %update particle
        particles(j) = updateParticle(particles(j), globalBestSol, globalBestFitness, rooms, numDays, numTimeSlots, noChangeProb, randomProb, pbestProb, gbestProb);

        %get new personal bests
        fitness = GetFitness(particles(j).schedule, students, Khard, Ksoft, false);

        if fitness < particles(j).personalBestFitness
            particles(j).personalBestSol = particles(j).schedule;
            particles(j).personalBestFitness = fitness;
        end

        if fitness < bestPartFitness
            bestPartSol = particles(j).schedule;
            bestPartFitness = fitness;
        end        
    end

    if bestPartFitness < globalBestFitness
        globalBestSol = bestPartSol;
        globalBestFitness = bestPartFitness;
    end
    
    fitnesses(i) = globalBestFitness; %#ok
    solutions(i) = globalBestSol; %#ok
    
    fprintf('iter: %d best: %d global best: %d\n',i,bestPartFitness,globalBestFitness);
    set(handle.Cur_Iter_val,'String', int2str(i));
    set(handle.Cur_Best_val,'String', int2str(globalBestFitness));
    drawnow;

end

bestSolution = globalBestSol;
bestFitness = globalBestFitness;

end

function [ newParticle ] = updateParticle(particle, globalBestSol, globalBestFitness, rooms, numDays, numTimeSlots, noChangeProb, randomProm, pbestProb, gbestProb)

 noChange = noChangeProb;
 random = randomProm + noChangeProb;
 takePbest = pbestProb + random;
 takeGbest = gbestProb + takePbest; %#ok unused since this is the 'else' case

coursemappings = particle.schedule.courseMappings;

for i = 1:length(coursemappings)
    %day
    randOp = rand;
    if randOp <= noChange
    elseif randOp < random
        randDay = round(numDays * rand + 0.5);
        coursemappings(i).day = randDay;
    elseif randOp <= takePbest
        coursemappings(i).day = particle.personalBestSol.courseMappings(i).day;
    else
        coursemappings(i).day = globalBestSol.courseMappings(i).day;
    end

    %timeslot
    randOp = rand;
    maxTimeslot = numTimeSlots - coursemappings(i).course.duration + 1;

    if randOp <= noChange
    elseif randOp <= random
        randTimeSlot = round(maxTimeslot * rand + 0.5);
        coursemappings(i).timeSlot = randTimeSlot;
    elseif randOp <= takePbest
        coursemappings(i).timeSlot = particle.personalBestSol.courseMappings(i).timeSlot;
    else
        coursemappings(i).timeSlot = globalBestSol.courseMappings(i).timeSlot;
    end

    %room
    randOp = rand;

    if randOp <= noChange
    elseif randOp <= random
        randRoom = randsample(rooms, 1);
        coursemappings(i).room = randRoom;
    elseif randOp <= takePbest
        coursemappings(i).room = particle.personalBestSol.courseMappings(i).room;
    else
        coursemappings(i).room = globalBestSol.courseMappings(i).room;
    end
end

sched = Schedule(coursemappings, numDays, numTimeSlots);

newParticle = Particle(sched, particle.personalBestSol, particle.personalBestFitness);
end

